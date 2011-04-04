class SubscriptionsController < ApplicationController
  resource_controller

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
