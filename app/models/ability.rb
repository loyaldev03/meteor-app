
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
    cannot :manage, User
    cannot :manage, UserNote
    cannot :manage, Membership
    cannot :manage, Operation
    cannot :manage, Partner
    cannot :manage, Product 
    cannot :manage, Prospect
    cannot :manage, TermsOfMembership
    cannot :manage, Transaction
    cannot :manage, PaymentGatewayConfiguration
    cannot :manage_club_cash_api, ClubCashTransaction
    cannot :see_sync_status, User
    cannot :see_cc_token, CreditCard
    cannot :api_enroll, User
    cannot :api_update, User
    cannot :api_profile, User
    cannot :api_update_club_cash, User
    cannot :api_change_next_bill_date, User
    cannot :api_cancel, User
    cannot :api_find_all_by_updated, User
    cannot :api_find_all_by_created, User
    cannot :api_change, TermsOfMembership
    cannot :api_sale, User
    cannot :api_get_banner_by_email, User
    cannot :manage_product_api, Product
    cannot :manage_prospects_api, Prospect
    cannot :manage_token_api, Agent
    cannot :manage_operations_api, Operation
    cannot :manage, DelayedJob
    cannot :manage, DispositionType
    cannot :see_nice, Transaction
    cannot :manage, UserAdditionalData
    cannot :manage, EmailTemplate
    cannot :chargeback, Transaction
    cannot :toggle_testing_account, User
    cannot :manual_review, Fulfillment
    cannot :bulk_process, Product
    cannot :send, Communication

    role = agent.roles.blank? ? agent.which_is_the_role_for_this_club?(club_id).role : agent.roles rescue nil

    case role
    when 'admin' then
      can :manage, User
      can :manage, Membership
      can :manage, CreditCard
      can :manage, Agent
      can :manage, Partner
      can :manage, Club
      can :manage, Domain
      can :manage, Product
      can :manage, Fulfillment
      can :manage, Operation
      can :manage, UserNote
      can :manage, TermsOfMembership
      can :manage, Transaction
      can :manage, PaymentGatewayConfiguration
      cannot :see_nice, Transaction
      can :manage, ClubCashTransaction
      can :manage, DelayedJob
      can :manage, DispositionType
      can :manage, UserAdditionalData
      can :manage_club_cash_api, ClubCashTransaction
      can :manage_prospects_api, Prospect
      can :manage_token_api, Agent
      can :manage_operations_api, Operation
      can :api_enroll, User
      can :api_update, User
      can :api_profile, User
      can :api_update_club_cash, User
      can :api_change_next_bill_date, User
      can :api_cancel, User
      can :api_find_all_by_updated, User
      can :api_find_all_by_created, User
      can :api_get_banner_by_email, User
      can :manage_product_api, Product
      can :api_change, TermsOfMembership
      can :api_sale, User
      can :list, Communication
      can :send, Communication
      can :manage, EmailTemplate
    when 'representative' then
      can :manage, User
      cannot :api_profile, User
      cannot :set_undeliverable, User
      cannot :see_sync_status, User
      cannot :api_update_club_cash, User
      cannot :api_change_next_bill_date, User
      cannot :api_cancel, User
      cannot :api_find_all_by_updated, User
      cannot :api_find_all_by_created, User
      cannot :api_get_banner_by_email, User
      cannot :no_recurrent_billing, User
      cannot :api_sale, User
      cannot :add_club_cash, User
      can :manage, Operation
      can :manage, CreditCard
      cannot :destroy, CreditCard
      cannot :see_cc_token, CreditCard
      can :manage, UserNote
      can :manage, UserAdditionalData
      can :see_nice, Transaction
      can :show, TermsOfMembership
      can :show, EmailTemplate
      can :refund, Transaction
      can :list, Membership
      can :list, Transaction
      can :list, ClubCashTransaction
      can :list, Communication
      can :list, Fulfillment
    when 'supervisor' then
      can :manage, User
      cannot :api_profile, User
      cannot :see_sync_status, User
      cannot :api_update_club_cash, User
      cannot :api_change_next_bill_date, User
      cannot :api_cancel, User
      cannot :api_find_all_by_updated, User
      cannot :api_find_all_by_created, User
      cannot :api_get_banner_by_email, User
      cannot :api_sale, User
      can :manage, Operation
      can :manage, UserNote
      can :manage, CreditCard
      can :manage, Transaction
      can :manage, ClubCashTransaction
      can :manage, UserAdditionalData
      can :show, TermsOfMembership
      can :show, EmailTemplate
      can :see_nice, Transaction
      can :list, Membership
      can :list, Communication
      can :list, Fulfillment
      can :manual_review, Fulfillment
    when 'api' then
      can :api_enroll, User
      can :api_update, User
      can :api_profile, User
      can :api_update_club_cash, User
      can :api_change_next_bill_date, User
      can :api_cancel, User
      can :api_find_all_by_updated, User
      can :api_find_all_by_created, User
      can :manage_product_api, Product
      can :manage_club_cash_api, ClubCashTransaction
      can :manage_prospects_api, Prospect
      can :manage_token_api, Agent
      can :manage_operations_api, Operation
      can :api_change, TermsOfMembership
      can :api_sale, User
      can :api_get_banner_by_email, User
    # Agency role: Team de acquisicion 
    when 'agency' then
      can :manage, Product
      can :read, Fulfillment
      can :list, Fulfillment
      can :report, Fulfillment
      can :read, User
      can :search_result, User    
      can :show, Operation
      can :show, TermsOfMembership
      can :show, EmailTemplate
      can :list, Membership
      can :list, Operation
      can :list, Transaction
      can :list, ClubCashTransaction
      can :list, CreditCard
      can :list, UserNote
      can :list, Communication
    # Fulfillment Managment role: Team de Fulfillment
    when 'fulfillment_managment' then
      can :manage, User
      cannot :api_profile, User
      cannot :see_sync_status, User
      cannot :api_update_club_cash, User
      cannot :api_change_next_bill_date, User
      cannot :api_find_all_by_updated, User
      cannot :api_find_all_by_created, User
      cannot :no_recurrent_billing, User
      cannot :api_get_banner_by_email, User
      cannot :manual_billing, User
      cannot :api_sale, User
      cannot :add_club_cash, User
      can :manage, Operation
      can :manage, CreditCard
      cannot :destroy, CreditCard
      cannot :see_cc_token, CreditCard
      can :manage, Product
      can :manage, UserNote
      can :manage, Fulfillment
      can :show, TermsOfMembership
      can :show, EmailTemplate
      can :refund, Transaction
      can :chargeback, Transaction
      can :list, Transaction
      can :list, ClubCashTransaction
      can :list, Communication
      can :list, Membership
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
