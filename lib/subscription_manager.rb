class SubscriptionManager
  include ActionView::Helpers::DateHelper

  def self.process
    active_subscriptions = Subscription.cim_subscriptions.active
    renew(active_subscriptions.backlog)
    check_for_creditcard_expiry(active_subscriptions) if Date.today.day == 1
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

      sub.renew
      if new_order.payments.last.state == 'completed'
        sub.reset_declined_count
        puts "Subscription renewed"
      else
        sub.declined
        SubscriptionsMailer.declined_creditcard_message(sub).deliver
        puts "There was an error proccesing the subscription. Subscription state set to 'error'. Subscription not renewed"
      end

    end
  end

  def self.check_for_creditcard_expiry(subscriptions)
    subscriptions.each do |subscription|
      creditcard = subscription.creditcard
      if creditcard.year == Date.today.year && (creditcard.month == Date.today.month || creditcard.month == 1.month.from_now)
        SubscriptionsMailer.expiring_creditcard_message(subscription).deliver
      elsif creditcard.year == Date.today.year && (creditcard.month == 1.month.ago.month)
        subscription.expire
        SubscriptionsMailer.expired_creditcard_message(subscription).deliver
      end
    end
  end

end

