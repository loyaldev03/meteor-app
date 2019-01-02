module Users
  class CancelUserRemoteDomainJob < ActiveJob::Base
    queue_as :drupal_queue

    def perform(user_id:)
      user = User.find user_id

      if user.api_user && !user.api_id.nil? && user.club.billing_enable
        res = user.api_user.destroy!
        raise 'CancelUserRemoteDomainJob::UnexpectedError: CMS Account not destroyed.' if res.nil? || !res.success?
      end
    end
  end
end
