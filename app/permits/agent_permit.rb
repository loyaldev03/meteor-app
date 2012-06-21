class AgentPermit < CanTango::UserPermit
  def initialize ability
    super
  end

  protected

  def permit_rules
    can :read, :all
    can :manage, Member
    can :write, Agent if user.id == 1 # example
    can :manage, Club do |club| # dynamic example
      club.id == 1
    end
  end

  module Cached
    def permit_rules
    end
  end

  module NonCached
    def permit_rules
    end
  end
end
