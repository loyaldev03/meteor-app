module Users
  class SendNeedsApprovalEmailJob < ActiveJob::Base
    queue_as :email_queue

    def perform(user_id:, active:)
      user = User.find user_id
      representatives = ClubRole.where(club_id: user.club_id, role: 'representative')
      emails = representatives.collect { |representative| representative.agent.email }.join(',')
      if active
        Notifier.active_with_approval(emails,user).deliver_later!
      else
        Notifier.recover_with_approval(emails,user).deliver_later!
      end
    end
  end
end