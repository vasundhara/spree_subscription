# add custom rake tasks here
  task :process => :environment do
    SubscriptionManager.process
  end

