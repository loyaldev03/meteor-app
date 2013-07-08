
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
    cannot :see_sync_status, Member
    cannot :see_cc_token, CreditCard
    cannot :api_enroll, Member
    cannot :api_update, Member
    cannot :api_profile, Member
    cannot :api_update_club_cash, Member
    cannot :api_change_next_bill_date, Member
    cannot :api_cancel, Member
    cannot :api_find_all_by_updated, Member
    cannot :api_find_all_by_created, Member
    cannot :manage_product_api, Product
    cannot :manage_prospects_api, Prospect
    cannot :manage_token_api, Agent
    cannot :manage_operations_api, Operation
    cannot :manage, DelayedJob
    cannot :manage, DispositionType

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
      can :manage, ClubCashTransaction
      can :api_enroll, Member
      can :api_update, Member
      can :api_profile, Member
      can :api_update_club_cash, Member
      can :api_change_next_bill_date, Member
      can :api_cancel, Member
      can :api_find_all_by_updated, Member
      can :api_find_all_by_created, Member
      can :manage_product_api, Product
      can :manage_club_cash_api, ClubCashTransaction
      can :manage_prospects_api, Prospect
      can :manage_token_api, Agent
      can :manage_operations_api, Operation
      can :manage, DelayedJob
      can :manage, DispositionType
    elsif agent.has_role_with_club? 'representative', club_id
      can :manage, Member
      cannot :api_profile, Member
      cannot :set_undeliverable, Member
      cannot :see_sync_status, Member
      cannot :api_update_club_cash, Member
      cannot :api_change_next_bill_date, Member
      cannot :api_cancel, Member
      cannot :api_find_all_by_updated, Member
      cannot :api_find_all_by_created, Member
      cannot :no_recurrent_billing, Member
      can :manage, Operation
      can :list, Membership
      can :manage, CreditCard
      cannot :destroy, CreditCard
      cannot :see_cc_token, CreditCard
      can :manage, MemberNote
      can :show, TermsOfMembership
      can :list, Transaction
      can :refund, Transaction
      can :list, ClubCashTransaction
    elsif agent.has_role_with_club? 'supervisor', club_id
      can :manage, Member
      cannot :api_profile, Member
      cannot :see_sync_status, Member
      cannot :api_update_club_cash, Member
      cannot :api_change_next_bill_date, Member
      cannot :api_cancel, Member
      cannot :api_find_all_by_updated, Member
      cannot :api_find_all_by_created, Member
      can :manage, Operation
      can :list, Membership
      can :manage, MemberNote
      can :manage, CreditCard
      can :show, TermsOfMembership
      can :manage, Transaction
      can :manage, ClubCashTransaction
    elsif agent.has_role_with_club? 'api', club_id
      can :api_enroll, Member
      can :api_update, Member
      can :api_profile, Member
      can :api_update_club_cash, Member
      can :api_change_next_bill_date, Member
      can :api_cancel, Member
      can :api_find_all_by_updated, Member
      can :api_find_all_by_created, Member
      can :manage_product_api, Product
      can :manage_club_cash_api, ClubCashTransaction
      can :manage_prospects_api, Prospect
      can :manage_token_api, Agent
      can :manage_operations_api, Operation
    # Agency role: Team de acquisicion 
    elsif agent.has_role_with_club? 'agency', club_id
      can :manage, Product
      can :read, Fulfillment
      can :report, Fulfillment
      can :read, Member
      can :search_result, Member    
      can :list, Membership
      can :list, Operation
      can :show, Operation
      can :show, TermsOfMembership
      can :list, Transaction
      can :list, ClubCashTransaction
    # Fulfillment Managment role: Team de Fulfillment
    elsif agent.has_role_with_club? 'fulfillment_managment', club_id
      can :manage, Member
      cannot :api_profile, Member
      cannot :see_sync_status, Member
      cannot :api_update_club_cash, Member
      cannot :api_change_next_bill_date, Member
      cannot :api_find_all_by_updated, Member
      cannot :api_find_all_by_created, Member
      cannot :no_recurrent_billing, Member
      cannot :manual_billing, Member
      can :manage, Operation
      can :list, Membership
      can :manage, CreditCard
      cannot :destroy, CreditCard
      cannot :see_cc_token, CreditCard
      can :manage, MemberNote
      can :show, TermsOfMembership
      can :list, Transaction
      can :refund, Transaction
      can :list, ClubCashTransaction
      can :manage, Product
      can :manage, Fulfillment
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
