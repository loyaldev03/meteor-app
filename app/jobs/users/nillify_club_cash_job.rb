module Users
  # Resets user club cash in case of a cancelation
  class NillifyClubCashJob < ActiveJob::Base
    queue_as :club_cash_queue

    def perform(user_id, message = 'Removing club cash because of member cancellation')
      user = User.find(user_id)
      if user.club.allow_club_cash_transaction?
        user.add_club_cash(nil, -user.club_cash_amount, message)
        if not user.is_drupal?
          user.club_cash_expire_date = nil
          user.save(validate: false)
        end
      end
    end
  end
end