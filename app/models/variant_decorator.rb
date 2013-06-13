Spree::Variant.class_eval do
  has_many :subscriptions
  
  @fields = [ {:name => 'Subscribable', :only => [:variant], :use => 'select', :value => lambda { |controller, field| [["False", false], ["True", true]]  } } ]
end
