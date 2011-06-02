require 'spree_core'
require 'spree_subscriptions_hooks'

module SpreeSubscriptions
  class Config
    @migrate_from_authorize_net_subscriptions = false
    @authorizenet_subscription_id_field       = nil

    class << self
      attr_accessor :migrate_from_authorize_net_subscriptions
      attr_accessor :authorizenet_subscription_id_field
    end
  end
  
  class AbilityDecorator
    include CanCan::Ability

    def initialize(user)
      user ||= User.new
      if user.has_role? 'admin'
        can :manage, :all
      else
        #############################
        can :read, Subscription do |subscription|
          subscription.user == user 
        end
        can :update, Subscription do |subscription|
          subscription.user == user 
        end
        can :create, Subscription
      end
    end
  end

  class Engine < Rails::Engine
    config.autoload_paths += %W(#{config.root}/lib)

    def self.activate
      Dir.glob(File.join(File.dirname(__FILE__), "../app/**/*_decorator*.rb")) do |c|
        Rails.env.production? ? require(c) : load(c)
      end

      Ability.register_ability(SpreeSubscriptions::AbilityDecorator)  
    end

    config.to_prepare &method(:activate).to_proc
  end

end
  
