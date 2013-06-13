class Subscription < ActiveRecord::Base
  belongs_to :user
  belongs_to :variant
  belongs_to :creditcard
  belongs_to :legacy_address, :class_name => "Address"

  belongs_to :parent_order, :class_name => "Order", :foreign_key => :created_by_order_id
  has_many :expiry_notifications
  has_many :subsequent_orders, :class_name => "Order", :foreign_key => :created_by_subscription_id

  #after_update :cancel_arb_in_authorize_net, :if => Proc.new { SpreeSubscriptions::Config.migrate_from_authorize_net_subscriptions && Rails.env.production?}
  before_destroy :cancel_arb_in_authorize_net

  accepts_nested_attributes_for :creditcard

  attr_accessible :interval, :duration, :user, :variant, :price, :next_payment_at, :creditcard, :created_by_order_id
  
  validates :price, :presence => true, :numericality => true
  validate :check_whole_dollar_amount
  
  state_machine :state, :initial => 'active' do
    event :cancel do
      transition :to => 'canceled', :if => :allow_cancel?
    end

    event :expire do
      transition :to => 'expired'
    end
    
    event :reactivate do
      transition :to => 'active', :from => ['expired', 'error', 'declined']
    end

    event :declined do
      transition 'active' => 'error', :if => :third_decline?
      transition 'active' =>  same
    end
    
    before_transition :on => :cancel, :do => :cancel_arb_in_authorize_net
    before_transition :on => :reactivate, :do => :sanctify
    before_transition :on => :declined, :do => :bump_up_declined_count
  end

  scope :cim_subscriptions, lambda{{:conditions => "next_payment_at IS NOT NULL"}}
  scope :arb_subscriptions, lambda{{:conditions => {:next_payment_at => nil}}}
  scope :active, lambda{{:conditions => {:state => "active"}}}
  scope :migrated_from_arb, lambda{{:conditions => "(old_authorizenet_subscription_id IS NOT NULL AND next_payment_at IS NOT NULL) OR (next_payment_at IS NULL AND old_authorizenet_subscription_id <> authorizenet_subscription_id)"}}
  scope :backlog, lambda{{:conditions => ["next_payment_at <= ? ", Time.now] }}

  def allow_cancel?
    self.state != 'canceled'
  end
  
  def inactive?
    self.state != 'active'
  end
 	
  def check_whole_dollar_amount
    errors.add(:price, "should be whole dollar amount") if self.price.to_i != self.price
  end

  def due_on
    next_payment_at
  end
	
  def renew
    self.update_attribute( :next_payment_at, next_payment_at + eval(self.duration.to_s + "." + self.interval.to_s) )
  end

  def is_cim? 
    self.next_payment_at.nil? ? false : true
  end

  def is_arb?
    !is_cim?
  end

  def type
    is_cim? ? "CIM" : "ARB" 
  end

  def migrated_from_arb?
    ( self.is_cim? && self.old_authorizenet_subscription_id != nil ) || (self.is_arb? && self.old_authorizenet_subscription_id != self.authorizenet_subscription_id ) ? true : false
  end

  def backlogged? 
    self.next_payment_at <= Time.now ? true : false
  end


  def cancel_arb_in_authorize_net
    if self.is_arb?
      arb_sub_id = self.send( SpreeSubscriptions::Config.authorizenet_subscription_id_field )
      gateway = Gateway.find(:first, :conditions => {:type => "Gateway::AuthorizeNet", :active => true, :environment => Rails.env})
      gateway.provider.cancel_recurring( arb_sub_id )
    end
  end

  def migrate_arb_to_cim
    if SpreeSubscriptions::Config.migrate_from_authorize_net_subscriptions && self.is_arb?
      self.cancel_arb_in_authorize_net
      self.next_payment_at = 1.month.from_now
      self.save
    end
  end


  def reset_declined_count
    self.update_attribute(:declined_count , 0)
  end


  def third_decline? 
    self.declined_count >= 2
  end

  def subscription_bill_address
    self.legacy_address || self.parent_order.bill_address
  end

  def subscription_ship_address
    self.legacy_address || self.parent_order.ship_address
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

    order.bill_address = self.subscription_bill_address
    order.ship_address = self.subscription_ship_address
    order.save!
    
    self.subsequent_orders << order
    self.save

    order.update_totals

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

  private

  def sanctify
    #method to reset the subscription before it is reactivated. Other related logic can go in this. 
    self.declined_count = 0
  end
  
  def bump_up_declined_count
    self.declined_count += 1
  end
end
