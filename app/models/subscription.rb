class Subscription < ActiveRecord::Base
	belongs_to :user
	belongs_to :variant
	belongs_to :creditcard
  belongs_to :legacy_address, :class_name => "Address"

        belongs_to :parent_order, :class_name => "Order", :foreign_key => :created_by_order_id
	has_many :expiry_notifications
        has_many :subsequent_orders, :class_name => "Order", :foreign_key => :created_by_subscription_id

        after_update :cancel_in_authorize_net, :if => Proc.new { SpreeSubscriptions::Config.migrate_from_authorize_net_subscriptions }
	
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
    
      gateway = Gateway.find(:first, :conditions => {:type => "Gateway::AuthorizeNet", :active => true, :environment => Rails.env})
      gateway.provider.cancel_recurring( arb_sub_id )
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
    payment.payment_method = PaymentMethod.find_by_type_and_environment("Gateway::AuthorizeNet", Rails.env)
    payment.amount = amount
    payment.response_code = transaction_id
    payment.state = 'completed'

    order.payments << payment

    order.state = 'complete'
    order.payment_state = 'paid'
    order.completed_at = Time.now
    order.save!

    order.bill_address = self.legacy_address
    order.ship_address = self.legacy_address
    order.save!

    order
  end

  def latest_subsequent_order
    self.subsequent_orders.order('created_at DESC').first
  end

  def self.populate_legacy_addresses
    temp = SpreeSubscriptions::Config.migrate_from_authorize_net_subscriptions
    SpreeSubscriptions::Config.migrate_from_authorize_net_subscriptions = false
    self.where('authorizenet_subscription_id > 0').each do |subscription|
      donation_schedule = DonationSchedule.find_by_authorizenet_subscription_id(subscription.authorizenet_subscription_id)
      subscription.legacy_address = donation_schedule.order_header.address
      subscription.save
    end
    SpreeSubscriptions::Config.migrate_from_authorize_net_subscriptions = temp
  end
end
