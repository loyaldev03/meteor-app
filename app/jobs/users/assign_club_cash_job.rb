module Users
  class AssignClubCashJob < ActiveJob::Base
    queue_as :club_cash_queue

    def perform(user_id, message, enroll = false)
      user    = User.find(user_id)
      amount  = enroll ? user.terms_of_membership.initial_club_cash_amount : user.terms_of_membership.club_cash_installment_amount
      user.add_club_cash(nil, amount, message)
      if !user.is_drupal? && !user.terms_of_membership.freemium? && user.club_cash_expire_date.nil?
        user.update_attribute :club_cash_expire_date, user.join_date + 1.year
      end
    end
  end
end
