class Subscription < ActiveRecord::Base
	belongs_to :user
	belongs_to :variant
	belongs_to :creditcard
        belongs_to :parent_order, :class_name => "Order", :foreign_key => :created_by_order_id
	has_many :payments, :dependent => :destroy, :order => :created_at
	has_many :expiry_notifications
        has_many :subsequent_orders, :class_name => "Order", :foreign_key => :created_by_subscription_id

  after_update :cancel_in_authorize_net, :if => SpreeSubscriptions::Config.migrate_from_authorize_net_subscriptions
	
	state_machine :state, :initial => 'active' do
    event :cancel do
      transition :to => 'canceled', :if => :allow_cancel?
    end

		event :expire do
			transition :to => 'expired', :from => 'active'
		end
		
		event :reactivate do
			transition :to => 'active', :from => 'expired'
		end
	end

	def allow_cancel?
    self.state != 'canceled'
  end
 	
	def due_on
    next_payment_at
	end
	
	def renew
    self.update_attribute( :next_payment_at, next_payment_at + eval(self.duration.to_s + "." + self.interval.to_s) )
	end

  def cancel_in_authorize_net
    if SpreeSubscriptions::Config.migrate_from_authorize_net_subscriptions && !self.send( SpreeSubscriptions::Config.authorizenet_subscription_id_field ).nil?
      arb_sub_id = self.send( SpreeSubscriptions::Config.authorizenet_subscription_id_field )
    
      Gateway.current.provider.cancel_recurring( arb_sub_id )
      self.update_attribute( SpreeSubscriptions::Config.authorizenet_subscription_id_field, nil )
    end
  end

  # I'm not sure why we need to save so much here.  I don't like it, but tests fail if we don't.
  def create_legacy_order(transaction_id, amount)
    order = Order.new
    order.save!

    order.user = self.user
    order.email = self.user.email
    order.save

    #Add a line item from the variant on this sub and set the price
    order.add_variant( self.variant )
    order.line_items.first.price = amount
    order.save

    #Process payment for the order
    payment = Payment.new
    payment.amount            = order.total 
    payment.response_code = transaction_id
    payment.payment_method = PaymentMethod.find_by_type_and_environment("Gateway::AuthorizeNet", Rails.env)

    order.payments << payment

    order.state = 'complete'
    order.completed_at = Time.now
    order.save!
  end
end
