Spree::CreditCard.class_eval	do
  has_one :subscription
  belongs_to :address
  before_update :update_last_digits
  accepts_nested_attributes_for :address, :allow_destroy => true, :reject_if => proc { |attrs| attrs['firstname'].blank? }
  attr_accessor :updating_from_user_account
  validates_presence_of :first_name, :last_name, :number, :verification_value, :month, :year, :on => :update, :if => :updating_from_user_account

  def update_last_digits
    number.to_s.gsub!(/\s/,'') unless number.nil?
    self.last_digits = number.to_s.length <= 4 ? number : number.to_s.slice(-4..-1) unless number.blank? 
  end
end
