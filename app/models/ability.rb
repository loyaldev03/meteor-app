class Ability
  include CanCan::Ability

  def initialize(agent, club_id = nil)
    
    cannot :manage, Agent
    cannot :manage, Partner
    cannot :manage, Club
    cannot :manage, ClubCashTransaction
    cannot :manage, CreditCard
    cannot :manage, Domain
    cannot :manage, Fulfillment
    cannot :manage, Member
    cannot :manage, MemberNote
    cannot :manage, Membership
    cannot :manage, Operation
    cannot :manage, Partner
    cannot :manage, Product 
    cannot :manage, Prospect
    cannot :manage, TermsOfMembership
    cannot :manage, Transaction
    cannot :manage_club_cash_api, ClubCashTransaction
    cannot :api_enroll, Member
    cannot :api_update, Member
    cannot :api_profile, Member
    cannot :manage_product_api, Product
    cannot :manage_prospects_api, Prospect
    cannot :manage_token_api, Agent

    if agent.has_role_with_club? 'admin', club_id
      can :manage, Member
      can :manage, Membership
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
      can :manage, Transaction
      can :api_enroll, Member
      can :api_update, Member
      can :api_profile, Member
      can :manage_product_api, Product
      can :manage_club_cash_api, ClubCashTransaction
      can :manage_prospects_api, Prospect
      can :manage_token_api, Agent
    elsif agent.has_role_with_club? 'representative', club_id
      can :manage, Member
      can :manage, Operation
      can :read, Membership
      cannot :enroll, Member
      cannot :api_enroll, Member
      cannot :api_profile, Member
      cannot :see_full_credit_card_number, CreditCard
      can :manage, MemberNote
      can :show, TermsOfMembership
      can :read, Transaction
    elsif agent.has_role_with_club? 'supervisor', club_id
      can :manage, Member
      can :manage, Operation
      can :read, Membership
      can :manage, MemberNote
      can :manage, CreditCard
      can :show, TermsOfMembership
      can :read, Transaction
      cannot :api_profile, Member
    elsif agent.has_role_with_club? 'api', club_id
      can :api_enroll, Member
      can :api_update, Member
      can :api_profile, Member
      can :manage_product_api, Product
      can :manage_club_cash_api, ClubCashTransaction
      can :manage_prospects_api, Prospect
      can :manage_token_api, Agent
    elsif agent.has_role_with_club? 'agency', club_id
      can :manage, Product
      can :report, Fulfillment
      can :read, Member             #Verificar que solo puede ver members
      can :search_result, Member    
      can :read, Membership
      can :list, Operation
      can :show, Operation
      can :show, TermsOfMembership
      can :read, Transaction
      cannot :enroll, Member     

      # admin products
      # admin fulfillments (only access to report, can't resend / mark as undelivered )
      # see members (read only mode). Any action/button on member profile must be denied.


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
