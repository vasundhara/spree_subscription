class Subscription < ActiveRecord::Base
	belongs_to :user
	belongs_to :variant
	belongs_to :creditcard
	has_many :payments, :dependent => :destroy, :order => :created_at
	has_many :expiry_notifications
	
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
end
