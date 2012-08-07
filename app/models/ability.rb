class Ability
  include CanCan::Ability

  def initialize(agent)
    

    if agent.has_role? 'admin'
      can :see_credit_card, CreditCard
      can :enroll_member, Member
      can :undo_credit_card_blacklist, CreditCard
      can :manage, Member
      can :manage, Agent
      can :manage, Partner
      can :manage, Club
      can :manage, Domain
      can :manage, Product
    elsif agent.has_role? 'representative'
      can :see_credit_card_last_digits, CreditCard
      can :read, Member
      can :update, Member
    elsif agent.has_role? 'supervisor'
<<<<<<< HEAD
      can :enroll_member, Member      
      can :read, Member
      can :update, Member
      can :see_credit_card, CreditCard
=======
      can :see_credit_card, CreditCard
      can :read, Agent
      can :read, Partner
      can :read, Club
>>>>>>> d7f3395ff15ea2b15ff08473475715ed13c395c0
      # EXAMPLE
      # can :manage, Partner do |partner|
      #   # agent is enabled to manage a specific partner
      #   agent.partners.include? partner
      # end
    end



    # Define abilities for the passed in user here. For example:
    #
    #   user ||= User.new # guest user (not logged in)
    #   if user.admin?
    #     can :manage, :all
    #   else
    #     can :read, :all
    #   end
    #
    # The first argument to `can` is the action you are giving the user permission to do.
    # If you pass :manage it will apply to every action. Other common actions here are
    # :read, :create, :update and :destroy.
    #
    # The second argument is the resource the user can perform the action on. If you pass
    # :all it will apply to every resource. Otherwise pass a Ruby class of the resource.
    #
    # The third argument is an optional hash of conditions to further filter the objects.
    # For example, here the user can only update published articles.
    #
    #   can :update, Article, :published => true
    #
    # See the wiki for details: https://github.com/ryanb/cancan/wiki/Defining-Abilities
  end
end
