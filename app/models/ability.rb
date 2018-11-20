
class Ability
  include CanCan::Ability

  def initialize(agent, club_id = nil)
    can :list, Agent
    cannot :manage, Agent
    cannot :manage, Partner
    cannot :manage, Club
    cannot :list_my_clubs, Club
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
    cannot :manage, Campaign
    cannot :manage, CampaignDay
    cannot :manage, CampaignProduct
    cannot :manage, TransportSetting
    cannot :manage, PreferenceGroup
    cannot :manage, Preference
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
    cannot :api_campaign_get_data, Campaign
    cannot :manage_product_api, Product
    cannot :manage_prospects_api, Prospect
    cannot :show_prospects_api, Prospect
    cannot :manage_token_api, Agent
    cannot :manage_operations_api, Operation
    cannot :manage, DelayedJob
    cannot :manage, DispositionType
    cannot :see_nice, Transaction
    cannot :manage, UserAdditionalData
    cannot :manage, EmailTemplate
    cannot :chargeback, Transaction
    cannot :toggle_testing_account, User
    cannot :toggle_vip_member, User
    cannot :manual_review, Fulfillment
    cannot :bulk_process, Product
    cannot :send, Communication
    cannot :unblacklist, User
    cannot :cancel_save_the_sale, Operation

    role = agent.roles.blank? ? agent.which_is_the_role_for_this_club?(club_id).role : agent.roles rescue nil

    case role
    when 'admin' then
      can :manage, User
      can :manage, Membership
      can :manage, CreditCard
      can :manage, Agent
      can :manage, Partner
      can :manage, Club
      can :list_my_clubs, Club
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
      can :manage, Campaign
      can :manage, CampaignDay
      can :manage, CampaignProduct
      can :manage, TransportSetting
      can :manage, PreferenceGroup
      can :manage, Preference
      can :manage_club_cash_api, ClubCashTransaction
      can :manage_prospects_api, Prospect
      can :show_prospects_api, Prospect
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
      can :api_campaign_get_data, Campaign
      can :manage_product_api, Product
      can :api_change, TermsOfMembership
      can :api_sale, User
      can :list, Communication
      can :send, Communication
      can :manage, EmailTemplate
      can :unblacklist, User
      can :cancel_save_the_sale, Operation
    when 'representative' then
      can :manage, User
      cannot :unblacklist, User
      cannot :api_profile, User
      cannot :set_undeliverable, User
      cannot :see_sync_status, User
      cannot :api_update_club_cash, User
      cannot :api_change_next_bill_date, User
      cannot :api_cancel, User
      cannot :api_find_all_by_updated, User
      cannot :api_find_all_by_created, User
      cannot :api_get_banner_by_email, User
      cannot :api_campaign_get_data, Campaign
      cannot :no_recurrent_billing, User
      cannot :api_sale, User
      cannot :add_club_cash, User
      cannot :toggle_vip_member, User
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
      can :list_my_clubs, Club
      cannot :cancel_save_the_sale, Operation
    when 'supervisor' then
      can :manage, User
      cannot :unblacklist, User
      cannot :api_profile, User
      cannot :see_sync_status, User
      cannot :api_update_club_cash, User
      cannot :api_change_next_bill_date, User
      cannot :api_cancel, User
      cannot :api_find_all_by_updated, User
      cannot :api_find_all_by_created, User
      cannot :api_get_banner_by_email, User
      cannot :api_campaign_get_data, Campaign
      cannot :api_sale, User
      cannot :toggle_vip_member, User
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
      can :list_my_clubs, Club
      cannot :cancel_save_the_sale, Operation
    when 'api' then
      can :api_enroll, User
      can :api_update, User
      can :api_profile, User
      can :api_update_club_cash, User
      can :api_change_next_bill_date, User
      can :api_cancel, User
      can :api_find_all_by_updated, User
      can :api_find_all_by_created, User
      can :list_my_clubs, Club
      can :manage_product_api, Product
      can :manage_club_cash_api, ClubCashTransaction
      can :manage_prospects_api, Prospect
      can :show_prospects_api, Prospect
      can :manage_token_api, Agent
      can :manage_operations_api, Operation
      can :api_change, TermsOfMembership
      can :api_sale, User
      can :api_get_banner_by_email, User
      cannot :cancel_save_the_sale, Operation
    when 'landing' then
      can :show_prospects_api, Prospect
      can :checkout_submit, Campaign
      can :checkout_new, Campaign
      can :checkout_create, Campaign
      can :api_campaign_get_data, Campaign
      cannot :cancel_save_the_sale, Operation
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
      can :list_my_clubs, Club
      cannot :cancel_save_the_sale, Operation
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
      cannot :api_campaign_get_data, Campaign
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
      can :list_my_clubs, Club
      can :unblacklist, User
      can :cancel_save_the_sale, Operation
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
