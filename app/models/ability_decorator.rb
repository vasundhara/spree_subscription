class AbilityDecorator
  include CanCan::Ability

  def initialize(user)
    user ||= User.new
    if user.has_role? 'admin'
      can :manage, :all
    else
      #############################
      can :index, Subscription
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

Ability.register_ability(AbilityDecorator)  
