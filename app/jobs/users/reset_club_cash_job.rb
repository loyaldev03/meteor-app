module Users
  class ResetClubCashJob < ActiveJob::Base
    queue_as :club_cash_queue

    def perform(user_id:)
      user = User.find user_id
      if user.club.allow_club_cash_transaction?
        if user.is_spree? and !user.terms_of_membership.freemium?
          amount_to_reset   = (user.terms_of_membership.initial_club_cash_amount + (Settings.vip_additional_club_cash if user.vip_member?).to_i) - user.club_cash_amount
          if amount_to_reset > 0
            user.add_club_cash(nil, amount_to_reset, "Reseting Club cash cash amount to #{amount_to_reset} for #{user.vip_member? ? 'vip member' : 'paid member'}.")
          end
        elsif !user.is_drupal?
          amount_to_reset   = -user.club_cash_amount
          user.add_club_cash(nil, amount_to_reset, 'Removing expired club cash.')
        end
      end
      user.club_cash_expire_date = user.club_cash_expire_date + 12.months
      user.save(:validate => false)
    end
  end
end
