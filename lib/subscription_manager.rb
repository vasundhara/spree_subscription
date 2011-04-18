include ActionView::Helpers::DateHelper
	
class SubscriptionManager
  def self.process
    subscriptions = Subscription.find(:all, :conditions => {:state => 'active'})
    check_for_renewals(subscriptions)
    check_for_creditcard_expiry(subscriptions)
  end

  def self.check_for_renewals(subscriptions)
    subscriptions.each do |sub|
      next unless sub.next_payment <= Time.now()
      #subscription due for renewal
                  
      #Create a new order
      orig_order = Order.find( sub.created_by_order_id )

      new_order = Order.new
      new_order.save!
      
      new_order.user = orig_order.user
      new_order.bill_address = orig_order.bill_address
      new_order.ship_address = orig_order.ship_address
      new_order.email        = orig_order.email
      new_order.save

      #Add a line item from the variant on this sub and set the price
      new_order.add_variant( sub.variant )
      new_order.line_items.first.price = sub.price
      new_order.save

      #Process payment for the order
      orig_payment = orig_order.payments.first
      new_payment = Payment.new
      new_payment.amount            = order.total 
      new_payment.source            = orig_payment.source
      new_payment.source_type       = orig_payment.source_type
      new_payment.payment_method_id = orig_payment.payment_method_id

      new_order.payments << new_payment

      #By setting to confirm we can do new_order.next and we get all the same
      #callbacks as if you were on the order form itself
      new_order.state = 'confirm'
      new_order.next
      new_order.save!

      #update the next_due date
      sub.renew
    end
  end

  #Toto: Fix this
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

end

