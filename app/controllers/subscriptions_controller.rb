class SubscriptionsController < ApplicationController
  resource_controller

  edit.before do
    if object.is_arb?
      @creditcard = object.build_creditcard
      @address = @creditcard.build_address
    end
  end
  
  update.after do
    if @object.is_arb? && @object.creditcard.present?
      gateway = Gateway.find(:first, :conditions => {:type => "Gateway::AuthorizeNetCim", :active => true, :environment => Rails.env})
      gateway.create_profile_from_card(@object.creditcard)
      @object.migrate_arb_to_cim
    end
  end

  def cancel
    params[:id] = params[:subscription_id]
    subscription = object

    subscription.cancel
    redirect_to subscriptions_path
  end

  private
    def object
      @object ||= end_of_association_chain.where( [ 'subscriptions.id = ? AND subscriptions.user_id = ?', params[:id], current_user.id ] ).first
    end

    def collection
      @collection ||= end_of_association_chain.where( [ 'subscriptions.user_id = ?', current_user.id ] )
    end
  
end
