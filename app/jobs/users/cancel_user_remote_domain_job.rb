module Users
  class CancelUserRemoteDomainJob < ActiveJob::Base
    queue_as :drupal_queue

    def perform(user_id:)
      user = User.find user_id
      res = user.api_user.destroy! unless user.api_user.nil? or user.api_id.nil? or not user.club.billing_enable
      if res.nil?
        raise "CancelUserRemoteDomainJob::UnexpectedError: CMS Account not destroyed."
      elseif !res.body['success']
        raise res.body['error_message']
      end
    end
  end
end