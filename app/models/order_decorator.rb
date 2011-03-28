Order.class_eval do
  before_save :subscriptions_check
  
  private 
  
  def process_creditcard?
    creditcard and not creditcard[:number].blank?
  end

  def subscriptions_check
    return unless process_creditcard?

    order = self #I'm lazy and want to see if this solves the problem.
    
    payment_profile_key = nil

    order.line_items.each do |line_item|
      if (line_item.variant.is_master? && line_item.variant.product.subscribable?) || (!line_item.variant.is_master? && line_item.variant.subscribable?)

      if payment_profile_key.nil?
          #setup payment profile
          gateway = Gateway.find(:first, :conditions => {:active => true, :environment => ENV['RAILS_ENV']})
          cc = order.payments[0].creditcard
          cc.number = creditcard[:number]
          
          #TODO: figure out why email address is not present in gateway options.
          gate_opts = cc.gateway_options
          gate_opts[:email] = order.user.email
          gate_opts[:customer] = order.user.email
          
          response = gateway.provider.store(cc, gate_opts)
          cc.gateway_error(response) unless response.success?
        
          payment_profile_key = response.params['customerCode']	
        end
        
        #get subscription info
        interval = line_item.variant.option_values.detect { |ov| ov.option_type.name == "subscription-interval"}.name || '1'
        duration = line_item.variant.option_values.detect { |ov| ov.option_type.name == "subscription-duration"}.name || 'month'

        #create subscription
        subscription = Subscription.create(	:interval => interval, 
                                            :duration => duration, 
                                            :user => order.user, 
                                            :variant => line_item.variant, 
                                            :creditcard => order.payments[0].creditcard,
                                            :payment_profile_key => payment_profile_key)
        
        #add dummy first payment (real payment was taken by normal checkout)
        payment = CreditcardPayment.create(:subscription => subscription, :amount => line_item.variant.price, :type => "CreditcardPayment", :creditcard => order.payments[0].creditcard)
        payment.creditcard_txns == order.payments[0].creditcard_txns
        subscription.payments << payment
        subscription.save
      end
    end
  end
end
