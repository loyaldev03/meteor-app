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

      def marketing_tool_mailchimp_sync
        mailchimp_after_create_sync_to_remote_domain
      end
      handle_asynchronously :marketing_tool_mailchimp_sync, :queue => :mailchimp_sync, priority: 30

      def mailchimp_subscribe
        mailchimp_member.subscribe!
      end
      handle_asynchronously :mailchimp_subscribe, :queue => :mailchimp_sync, priority: 30

      def mailchimp_unsubscribe
        time_elapsed = Benchmark.ms do
          mailchimp_after_create_sync_to_remote_domain
          mailchimp_member.unsubscribe!
        end
        logger.info "SacMailchimp::unsubscribe_subscriber took #{time_elapsed}ms"
      rescue Exception => e
        logger.error "* * * * * #{e}"
        Auditory.report_issue("Member:unsubscribe_subscriber", e, { :member => self.inspect }) unless e.to_s.include?("Timeout")
        raise e
      end
      handle_asynchronously :mailchimp_unsubscribe, :queue => :mailchimp_sync, priority: 30

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
          Auditory.report_issue("Member:mailchimp_member", 'Mandrill not configured correctly', { :club => self.club.inspect })
          nil
        end
      end

      def skip_mailchimp_sync!
        @skip_mailchimp_sync = true
      end
    end
  end
end