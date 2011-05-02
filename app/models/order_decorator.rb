Order.class_eval do
  has_many :subscriptions, :foreign_key => :created_by_order_id

  belongs_to :parent_subscription, :foreign_key => :created_by_subscription_id, :class_name => "Subscription"
  
  def finalize_with_subscriptions_check!
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
                                            :price    => line_item.price,
                                            :next_payment_at => Time.now + eval(duration.to_s + "." + interval.to_s),
                                            :creditcard => order.creditcards[0],
                                            :created_by_order_id => order.id )
        
        #add dummy first payment (real payment was taken by normal checkout)
        #payment = CreditcardPayment.create(:subscription => subscription, :amount => line_item.variant.price, :type => "CreditcardPayment", :creditcard => cc)
        #payment.creditcard_txns = order.payments[0].creditcard_txns
        #subscription.payments << payment
        #subscription.save
      end
    end unless order.created_by_subscription? #Does not add subscription if the order is created from the subscription manager ie it is a subsequent order
    finalize_without_subscriptions_check!
  end

  alias_method_chain :finalize!, :subscriptions_check

  def contains_subscription?
    line_items.any? { |line_item| line_item.variant.subscribable? }
  end

  def created_by_subscription?
    self.parent_subscription.present?
  end
  
end unless LineItem.instance_methods.include? :finalize_with_subscriptions_check!
