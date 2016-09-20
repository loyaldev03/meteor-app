module Users
  class CancelUserRemoteDomainJob < ActiveJob::Base
    queue_as :drupal_queue

    def perform(user_id:)
      user = User.find user_id
      user.api_user.destroy! unless user.api_user.nil? or user.api_id.nil? or not user.club.billing_enable
    end
  end
end