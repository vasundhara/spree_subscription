Spree::CheckoutController.class_eval do
  before_filter :check_subscriptions_for_registration, :except => [:registration, :update_registration]

  private

  # Go to the registration step if any subscribables and no current_user
  def check_subscriptions_for_registration
    return unless Spree::Auth::Config[:registration_step]
    return if current_user
    if current_order.contains_subscription?
      store_location
      redirect_to checkout_registration_path
    end
  end
end
