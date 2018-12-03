module Users
  class CancelUserRemoteDomainJob < ActiveJob::Base
    queue_as :drupal_queue

    def perform(user_id:)
      user  = User.find user_id
      if user.api_user and !user.api_id.nil? and user.club.billing_enable
        res = user.api_user.destroy! 
        raise 'CancelUserRemoteDomainJob::UnexpectedError: CMS Account not destroyed.' if res.nil?
        raise res.body['error_message'] if !res.body['success']
      end
    end
  end
end
