module Mailchimp
  class UserUpdateEmailJob < ActiveJob::Base
    queue_as :mailchimp_sync

    def perform(user_id, former_email)
      logger       = Logger.new("#{Rails.root}/log/mailchimp_client.log")
      user         = User.find user_id
      time_elapsed = Benchmark.ms do
        user.mailchimp_member.update_email!(former_email)
      end
      logger.info "SacMailchimp::update_email took #{time_elapsed}ms"
    end
  end
end