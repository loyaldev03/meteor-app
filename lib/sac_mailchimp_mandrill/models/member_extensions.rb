module SacMailchimp
	module MemberExtensions
    def self.included(base)
      base.send :include, InstanceMethods
    end

    module InstanceMethods
      def mailchimp_after_create_sync_to_remote_domain
        mailchimp_sync_to_remote_domain unless mailchimp_member.nil?
      end

      def mailchimp_sync_to_remote_domain
        return if @skip_mailchimp_sync
        time_elapsed = Benchmark.ms do
          mailchimp_member.save!
        end
        logger.info "SacMailchimp::sync took #{time_elapsed}ms"
      rescue Exception => e
        Auditory.report_issue("Member:mailchimp_sync", e, { :member => self.inspect }) unless e.to_s.include?("Timeout")
        raise e
      end

      def mailchimp_sync?
        self.club.mailchimp_sync?
      end

      def mailchimp_member
        if self.club.marketing_tool_attributes and not self.club.marketing_tool_attributes["mailchimp_api_key"].blank? and not self.club.marketing_tool_attributes["mailchimp_list_id"].blank?
          SacMailchimp.config_integration(self.club.marketing_tool_attributes["mailchimp_api_key"])
          @mailchimp_member ||= if !self.mailchimp_sync?
            nil
          else
            SacMailchimp::MemberModel.new self
          end
        else
          Auditory.report_issue("Member:mailchimp_member", 'Mandrill not configured correctly', { :member => self.club.inspect })
          nil
        end
      end

      def skip_mailchimp_sync!
        @skip_mailchimp_sync = true
      end
    end
  end
end