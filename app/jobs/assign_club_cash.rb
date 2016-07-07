class AssignClubCash < ActiveJob::Base
  queue_as :club_cash_queue

  def perform(user_id, message, enroll = false, is_not_drupal = true)
    user = User.find(user_id)
    amount = enroll ? user.terms_of_membership.initial_club_cash_amount : user.terms_of_membership.club_cash_installment_amount
    user.add_club_cash(nil, amount, message)
    if is_not_drupal
      if user.club_cash_expire_date.nil? # first club cash assignment
        user.update_attribute :club_cash_expire_date, user.join_date + 1.year
      end
    end
  end
end
