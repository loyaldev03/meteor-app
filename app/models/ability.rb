class Ability
  include CanCan::Ability

  def initialize(agent)
    
    if agent.has_role? 'admin'
      can :see_credit_card, CreditCard
      can :enroll_member, Agent
      can :undo_credit_card_blacklist, CreditCard
      can :manage, Member
      can :manage, CreditCard
      can :manage, Agent
      can :manage, Partner
      can :manage, Club
      can :manage, Domain
      can :manage, Product
      can :manage, Fulfillment
      can :manage, Operation
      can :manage, MemberNote
      can :manage, TermsOfMembership
      can :api_enroll, Member
      can :api_update, Member
      can :api_profile, Member
      can :manage_product_api, Product
      can :manage_club_cash_api, ClubCashTransaction
      can :manage_prospects_api, Prospect
      can :manage_token_api, Agent
      can :see_sync_status, Member
    elsif agent.has_role? 'representative'
      can :manage, Member
      cannot :enroll, Member
      cannot :api_enroll, Member
      can :api_update, Member
      cannot :api_profile, Member
      can :manage, MemberNote
      can :manage_token_api, Agent
      can :see_credit_card_last_digits, CreditCard
    elsif agent.has_role? 'supervisor'
      can :manage, Member
      can :api_enroll, Member
      can :api_update, Member
      cannot :api_profile, Member
      can :manage, MemberNote
      can :manage_token_api, Agent
      can :see_credit_card, CreditCard
    elsif agent.has_role? 'api'
      can :api_enroll, Member
      can :api_update, Member
      can :api_profile, Member
      can :manage_product_api, Product
      can :manage_club_cash_api, ClubCashTransaction
      can :manage_prospects_api, Prospect
      can :manage_token_api, Member
    elsif agent.has_role? 'agency'
      can :manage, Product
      can :read, Club
      can :read, Fulfillment
      can :report, Fulfillment
      can :read, Member
      can :search_result, Member
      cannot :enroll, Member
      cannot :api_enroll, Member
      cannot :api_update, Member
      cannot :api_profile, Member
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
