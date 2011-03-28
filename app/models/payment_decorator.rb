Payment.class_eval do
  belongs_to :subscription

  private
  def check_payments                            
    return unless subscription_id.nil? 
    return unless order.checkout_complete    
    order.pay! if order.payment_total >= order.total
  end
end
