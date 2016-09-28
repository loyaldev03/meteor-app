module Mailchimp
  class ProspectSynchronizationJob < ActiveJob::Base
    queue_as :mailchimp_sync

    def perform(prospect_id)
      logger       = Logger.new("#{Rails.root}/log/mailchimp_client.log")
      prospect     = Prospect.find(prospect_id)
      time_elapsed = Benchmark.ms do
        prospect.mailchimp_sync_to_remote_domain(prospect.club) if prospect.mailchimp_member
      end
      logger.info "SacMailchimp::sync took #{time_elapsed}ms"
    end
  end
end