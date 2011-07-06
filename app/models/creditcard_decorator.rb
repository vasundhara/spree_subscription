Creditcard.class_eval	do
  has_one :subscription
  belongs_to :address
  accepts_nested_attributes_for :address, :allow_destroy => true, :reject_if => proc { |attrs| attrs['firstname'].blank? }
end
