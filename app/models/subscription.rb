class Subscription < ActiveRecord::Base
	belongs_to :user
	belongs_to :variant
	belongs_to :creditcard
	has_many :payments, :dependent => :destroy, :order => :created_at
	has_many :expiry_notifications

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
    next_payment
	end
	
	def renew
    self.update_attribute( :next_payment, Time.now + eval(self.duration.to_s + "." + self.interval.to_s) )
	end

  def cancel_in_authorize_net
    if SpreeSubscriptions::Config.migrate_from_authorize_net_subscriptions && !self.send( SpreeSubscriptions::Config.authorizenet_subscription_id_field ).nil?
      arb_sub_id = self.send( SpreeSubscriptions::Config.authorizenet_subscription_id_field )
    
      Gateway.current.provider.cancel_recurring( arb_sub_id )
    end
  end
end
