module SacMailchimp
	module ProspectExtensions
    def self.included(base)
      base.send :include, InstanceMethods
    end

    module InstanceMethods
      def mailchimp_after_create_sync_to_remote_domain
        mailchimp_sync_to_remote_domain unless mailchimp_prospect.nil?
      end

      def mailchimp_sync_to_remote_domain
        return if @skip_mailchimp_sync
        time_elapsed = Benchmark.ms do
          mailchimp_prospect.save!(club)
        end
        logger.info "SacMailchimp::sync took #{time_elapsed}ms"
      rescue Exception => e
        Auditory.report_issue("Prospect:mailchimp_sync", e, { :prospect => self.inspect }) unless e.to_s.include?("Timeout")
        raise e
      end

      def mailchimp_sync?
        self.club.mailchimp_sync?
      end

      def mailchimp_prospect
        if self.club.marketing_tool_attributes and not self.club.marketing_tool_attributes["mailchimp_api_key"].blank? and not self.club.marketing_tool_attributes["mailchimp_list_id"].blank?
          SacMailchimp.config_integration(self.club.marketing_tool_attributes["mailchimp_api_key"])
          @mailchimp_prospect ||= if !self.mailchimp_sync?
            nil
          else
            SacMailchimp::ProspectModel.new self
          end
        else
          Auditory.report_issue("Prospect:mailchimp_prospect", 'Mandrill not configured correctly', { :club => self.club.inspect })
          nil
        end
      end

      def skip_mailchimp_sync!
        @skip_mailchimp_sync = true
      end
    end
  end
end