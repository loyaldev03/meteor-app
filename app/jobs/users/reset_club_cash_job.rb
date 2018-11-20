module Users
  class ResetClubCashJob < ActiveJob::Base
    queue_as :club_cash_queue

    def perform(user_id:)
      user = User.find user_id
      if user.club.allow_club_cash_transaction?
        amount_to_reset   = -user.club_cash_amount
        operation_message = 'Removing expired club cash.'
        
        if user.is_spree?
          amount_to_reset   = user.vip_member? ? Settings.club_cash_vip_default_amount : user.terms_of_membership.initial_club_cash
          operation_message = "Reseting Club cash cash amount to #{amount_to_reset} for #{user.vip_member? ? 'vip member' : 'paid member'}."
        end
        
        user.add_club_cash(nil, amount_to_reset, message)
        unless user.is_drupal?
          user.club_cash_expire_date = user.club_cash_expire_date + 12.months
          user.save(:validate => false)
        end
      end
    end
  end
end