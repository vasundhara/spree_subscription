class SpreeSubscriptionsHooks < Spree::ThemeSupport::HookListener
  insert_after :admin_product_form_right, "shared/ext_subscription_admin_product_fields"
  
  #insert_after :admin_tabs do
  #  %(<%= tab(:subscriptions)  %>)
  #end
end
