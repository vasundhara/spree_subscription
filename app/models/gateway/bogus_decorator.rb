Spree::Gateway::Bogus.class_eval do
  def store(creditcard, options = {})      
    if Spree::Gateway::Bogus::VALID_CCS.include? creditcard.number 
      ActiveMerchant::Billing::Response.new(true, "Bogus Gateway: Forced success", {}, :test => true, :customerCode => '12345')
    else
      ActiveMerchant::Billing::Response.new(false, "Bogus Gateway: Forced failure", {:message => 'Bogus Gateway: Forced failure'}, :test => true)
    end      
  end
end
