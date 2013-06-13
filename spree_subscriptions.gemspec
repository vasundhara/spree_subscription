# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "spree_subscriptions"
  s.version = "0.1.12"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Jeff McFadden"]
  s.date = "2013-06-10"
  s.description = "Make products or variants subscribable"
  s.files = [".gitignore", "LICENSE", "README.md", "Rakefile", "app/controllers/admin/payments_controller_decorator.rb", "app/controllers/admin/subscriptions_controller.rb", "app/controllers/checkout_controller_decorator.rb", "app/controllers/creditcards_controller.rb", "app/controllers/subscriptions_controller.rb", "app/helpers/creditcards_helper.rb", "app/helpers/subscriptions_helper.rb", "app/mailers/creditcard_expired.html.erb", "app/mailers/expiry_warning.html.erb", "app/mailers/paymenet_receipt.html.erb", "app/mailers/subscription_reactivated.html.erb", "app/models/ability_decorator.rb", "app/models/address_decorator.rb", "app/models/creditcard_decorator.rb", "app/models/expiry_notification.rb", "app/models/gateway/bogus_decorator.rb", "app/models/order_decorator.rb", "app/models/product_decorator.rb", "app/models/subscription.rb", "app/models/subscription_mailer.rb", "app/models/user_decorator.rb", "app/models/variant_decorator.rb", "app/views/admin/payments/index.html.erb.bak", "app/views/admin/shared/_subscription_tabs.html.erb", "app/views/admin/subscriptions/_form.html.erb", "app/views/admin/subscriptions/edit.html.erb", "app/views/admin/subscriptions/index.html.erb", "app/views/creditcards/_form.html.erb", "app/views/creditcards/edit.html.erb", "app/views/shared/_ext_subscription_admin_product_fields.html.erb", "app/views/subscriptions/index.html.erb", "app/views/subscriptions/show.html.erb", "app/views/users/show.html.erb", "config/routes.rb", "config/schedule.rb", "db/migrate/20110300113493_add_fields_to_variant.rb", "db/migrate/20110301132144_create_subscriptions.rb", "db/migrate/20110301134135_add_cc_to_subscription.rb", "db/migrate/20110301150301_create_expiry_notifications.rb", "db/migrate/20110302332500_add_option_types_and_values.rb", "db/migrate/20110330140000_add_price_to_subscription.rb", "db/migrate/20110419200748_change_data_type_of_next_payment_at.rb", "db/migrate/20110426174608_add_column_created_by_subscription_id_to_orders.rb", "db/migrate/20110503221735_add_legacy_address_id_to_subscriptions.rb", "db/migrate/20110823145520_add_declined_count_to_subscriptions.rb", "db/seeds.rb", "lib/spree_subscriptions.rb", "lib/spree_subscriptions_hooks.rb", "lib/subscription_manager.rb", "lib/tasks/install.rake", "lib/tasks/spree_subscriptions.rake", "spec/spec_helper.rb", "spree_subscriptions.gemspec"]
  s.require_paths = ["lib"]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.2")
  s.requirements = ["none"]
  s.rubygems_version = "1.8.25"
  s.summary = "Make products or variants subscribable"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<spree_core>, [">= 0.50.00"])
    else
      s.add_dependency(%q<spree_core>, [">= 0.50.00"])
    end
  else
    s.add_dependency(%q<spree_core>, [">= 0.50.00"])
  end
end
