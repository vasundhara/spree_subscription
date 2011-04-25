# add custom rake tasks here
namespace :subscriptions do
  desc "Processes Subscriptions"
  task :process => :environment do
    SubscriptionManager.process
  end
end

