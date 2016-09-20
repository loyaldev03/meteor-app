module Users
  class ResetClubCashJob < ActiveJob::Base
    queue_as :club_cash_queue

    def perform(user_id:)
      user = User.find user_id
      if user.club.allow_club_cash_transaction?
        user.add_club_cash(nil, -user.club_cash_amount, 'Removing expired club cash.')
        if user.is_not_drupal?
          user.club_cash_expire_date = user.club_cash_expire_date + 12.months
          user.save(:validate => false)
        end
      end
    end
  end
end