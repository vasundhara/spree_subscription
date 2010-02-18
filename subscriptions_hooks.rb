class SubscriptionsHooks < Spree::ThemeSupport::HookListener
  insert_after :admin_tabs do
    %(<%= tab(:subscriptions)  %>)
  end
end