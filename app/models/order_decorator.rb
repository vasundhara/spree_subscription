Order.class_eval do
  
  def subscriptions_check
    order = self #I'm lazy and want to see if this solves the problem.
    
    order.line_items.each do |line_item|
      if (line_item.variant.is_master? && line_item.variant.product.subscribable?) || (!line_item.variant.is_master? && line_item.variant.subscribable?)

        #get subscription info
        interval = line_item.variant.option_values.detect { |ov| ov.option_type.name == "subscription-interval"}
        duration = line_item.variant.option_values.detect { |ov| ov.option_type.name == "subscription-duration"}

        #Default of 1 month if no options were set
        interval = ( interval.nil? ? 'month' : interval.name )
        duration = ( duration.nil? ? '1' : duration.name )

        #create subscription
        subscription = Subscription.create(	:interval => interval, 
                                            :duration => duration, 
                                            :user => order.user, 
                                            :variant => line_item.variant, 
                                            :creditcard => order.creditcards[0] )
        
        #add dummy first payment (real payment was taken by normal checkout)
        #payment = CreditcardPayment.create(:subscription => subscription, :amount => line_item.variant.price, :type => "CreditcardPayment", :creditcard => cc)
        #payment.creditcard_txns = order.payments[0].creditcard_txns
        #subscription.payments << payment
        #subscription.save
      end
    end
  end

  alias_method :original_finalize!, :finalize!
  alias_method :finalize!, :subscriptions_check

  
end