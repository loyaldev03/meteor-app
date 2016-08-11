module Mailchimp
  class UserUnsubscribeJob < ActiveJob::Base
    queue_as :mailchimp_sync

    def perform(user_id)
      user   = User.find(user_id)
      if user.mailchimp_member
        logger       = Logger.new("#{Rails.root}/log/mailchimp_client.log")
        time_elapsed = Benchmark.ms do
          user.mailchimp_sync_to_remote_domain!
          user.mailchimp_member.unsubscribe!
        end
        logger.info "SacMailchimp::unsubcribe took #{time_elapsed}ms"
      end
    end
  end
end