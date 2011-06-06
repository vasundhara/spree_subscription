class CreditcardsController < ApplicationController
  before_filter :load_data, :only => :update
  resource_controller

  update.success.wants.html { redirect_to subscription_url(@subscription) }

  update.after do
  	if @subscription.state == "expired"
  #			@subscription.reactive
  #		
  #		SubscriptionMailer.deliver_subscription_reactivated(@subscription) 
    end

    # cim_gateway gets us the actual AuthorizeNetCIM from ActiveMerchant
    # and we have to delete the old profile because we don't want to
    # accidentally create a duplicate
    Gateway.cim_gateway.delete_customer_profile( @subscription.creditcard.gateway_customer_profile_id ) unless @subscription.creditcard.gateway_customer_profile_id.nil?

    # Create the payment profile for this card
    Gateway.current.create_profile_from_card( @subscription.creditcard )
  end

	private
	def load_data
	  @subscription = Subscription.find(params[:subscription_id])
	end
end
