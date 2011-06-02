Rails.application.routes.draw do
 
  scope "/account" do
    resources :subscriptions do
      put 'cancel'
      
      resources :creditcards
    end
  end
  
  namespace "admin" do
	  resources :subscriptions, :has_many => [:payments, :creditcards], :member => {:fire => :put}
    #resources :subscriptions do |subscriptions|
		#  subscriptions.resources :creditcard_payments
	  #end
  end
end
