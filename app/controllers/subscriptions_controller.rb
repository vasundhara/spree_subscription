class SubscriptionsController < ApplicationController
  resource_controller

  private
    def collection
      @collection ||= end_of_association_chain.where( [ 'subscriptions.user_id = ?', current_user.id ] )
    end
  
end
