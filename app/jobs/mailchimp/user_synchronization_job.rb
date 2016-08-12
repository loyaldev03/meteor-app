module Mailchimp
  class UserSynchronizationJob < ActiveJob::Base
    queue_as :mailchimp_sync

    def perform(user_id)
      logger       = Logger.new("#{Rails.root}/log/mailchimp_client.log")
      user         = User.find(user_id)
      time_elapsed = Benchmark.ms do
        user.mailchimp_sync_to_remote_domain! if user.mailchimp_member
      end
      logger.info "SacMailchimp::sync took #{time_elapsed}ms"
    end
  end
end