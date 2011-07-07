class SubscriptionManager
  include ActionView::Helpers::DateHelper

  def self.process
    subscriptions = Subscription.cim_subscriptions.active.backlog
    renew(subscriptions)
#   check_for_creditcard_expiry(subscriptions)
  end

  def self.renew(subscriptions)
    subscriptions.each do |sub|
      #subscription due for renewal
      puts "Processing Subscription with id #{sub.id}"
                  
      #Create a new order
      recently_migrated_from_arb_to_cim  = sub.parent_order.nil? ? true : false

      if recently_migrated_from_arb_to_cim 

        new_order = sub.build_parent_order
        new_order.user = sub.user
        new_order.bill_address = sub.legacy_address
        new_order.ship_address = sub.legacy_address
        new_order.email = sub.user.email
        new_order.parent_subscription = sub #this order becomes both a subsequent order and the parent order to avoid creating another subscription 
        new_order.save

        new_order.add_variant( sub.variant )
        #NOTE settting quantity as opposed to price becuase during processing payments the order and price will get flipped
        new_order.line_items.first.quantity = sub.price.to_i #doing this will clip a price like 8.8 to 8)
        new_order.line_items.first.price = 1
        new_order.save

        new_payment = Payment.new
        new_payment.amount = sub.price
        new_payment.source = sub.creditcard
        new_payment.source_type = "Creditcard"
        new_payment.payment_method = PaymentMethod.find_by_type_and_environment("Gateway::AuthorizeNetCim", Rails.env)

      else

        new_order = sub.subsequent_orders.build
        new_order.save!
        
        template_order = sub.parent_order
        new_order.user = template_order.user
        new_order.bill_address = template_order.bill_address
        new_order.ship_address = template_order.ship_address
        new_order.email        = template_order.email
        new_order.save

        #Add a line item from the variant on this sub and set the price
        new_order.add_variant( sub.variant )
        #NOTE settting quantity as opposed to price becuase during processing payments the order and price will get flipped
        new_order.line_items.first.quantity = sub.price.to_i #doing this will clip a price like 8.8 to 8)
        new_order.line_items.first.price = 1
        new_order.save

        #Process payment for the order
        template_payment = template_order.payments.first
        new_payment = Payment.new
        new_payment.amount            = new_order.total 
        new_payment.source            = template_payment.source
        new_payment.source_type       = template_payment.source_type
        new_payment.payment_method_id = template_payment.payment_method_id

      end

      new_order.payments << new_payment
      new_order.update! #updating totals

      #By setting to confirm we can do new_order.next and we get all the same
      #callbacks as if you were on the order form itself
      new_order.state = 'confirm'
      new_order.next
      new_order.save!

      puts "Order number: #{sub.subsequent_orders.last.number} created"

      if new_order.payments.last.state == 'completed'
        #update the next_due date
        sub.renew
        puts "Subscription renewed"
      else
        sub.error 
        puts "There was an error proccesing the subscription. Subscription state set to 'error'. Subscription not renewed"
      end

    end
  end

  #Toto: Fix this
=begin
  def self.check_for_creditcard_expiry(subscriptions)
    return #Not implemented for rails 3 yet.

    subscriptions.each do |sub|
      next unless sub.creditcard.expiry_date.expiration < (Time.now + 3.months)
      
      #checks for credit cards due to expiry with all the following ranges
      [1.day, 3.days, 1.week, 2.weeks, 3.weeks, 1.month, 2.months, 3.months].each do |interval|
        within =  distance_of_time_in_words(Time.now, Time.now + interval)
                                        
        if sub.creditcard.expiry_date.expiration.to_time < (Time.now + interval) && sub.end_date.to_time > (Time.now + interval) 
          unless ExpiryNotification.exists?(:subscription_id => sub.id, :interval => interval.seconds.to_i)
            notification = ExpiryNotification.create(:subscription_id => sub.id, :interval => interval.seconds)
            SubscriptionMailer.deliver_expiry_warning(sub, within)
          end

          break
        end
      end
      
      #final check if credit card has actually expired
      if sub.creditcard.expiry_date.expiration < Time.now 
        sub.expire
        SubscriptionMailer.deliver_creditcard_expired(sub)
      end
          
    end		
  end
=end

end

