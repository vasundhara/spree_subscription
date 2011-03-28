Admin::PaymentsController.class_eval do
  belongs_to :subscription
  before_filter :load_data
  
  private
  def load_data
    if params.key? "subscription_id"
      @subscription = Subscription.find(params[:subscription_id])
    end
  end
  
end
