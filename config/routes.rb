Rails.application.routes.draw do
  resources :subscriptions, :has_many => [:creditcards]
  
  namespace "admin" do
	  resources :subscriptions, :has_many => [:payments, :creditcards], :member => {:fire => :put}
    #resources :subscriptions do |subscriptions|
		#  subscriptions.resources :creditcard_payments
	  #end
  end
end
