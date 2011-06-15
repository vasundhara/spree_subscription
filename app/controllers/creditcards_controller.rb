class CreditcardsController < ApplicationController
  before_filter :load_data, :only => :update
  resource_controller

  update.success.wants.html { redirect_to subscription_url(@subscription) }

  update.after do
    # cim_gateway gets us the actual AuthorizeNetCIM from ActiveMerchant
    # and we have to delete the old profile because we don't want to
    # accidentally create a duplicate
    gateway = Gateway.find(:first, :conditions => {:type => "Gateway::AuthorizeNetCim", :active => true, :environment => Rails.env})
    gateway.delete_customer_profile( @subscription.creditcard.gateway_customer_profile_id ) unless @subscription.creditcard.gateway_customer_profile_id.nil?

    # Create the payment profile for this card
    gateway.create_profile_from_card( @subscription.creditcard )
  end

  private
  def load_data
    @subscription = Subscription.find(params[:subscription_id])
  end
end
