module SacMailchimp
	module MemberExtensions
    def self.included(base)
      base.send :extend, ClassMethods
      base.send :include, InstanceMethods
    end

    module ClassMethods
      def sync_members_to_mailchimp
        base = Member.joins(:club)where("need_sync_to_marketing_client = 1 and marketing_tool_client = 'mailchimp_mandrill'")
        Rails.logger.info " *** [#{I18n.l(Time.zone.now, :format =>:dashed)}] Starting members:sync_members_to_mailchimp, processing #{base.count} members"
        base.find_in_batches do |group|
          group.each_with_index do |member,index|
            tz = Time.zone.now
            begin
              Rails.logger.info "  *[#{index+1}] processing member ##{member.id}"
              member.marketing_tool_mailchimp_sync_without_delay
            rescue Exception => e
              Auditory.report_issue("Member::SyncExactTargetWithBatch", "#{e.to_s}\n\n#{$@[0..9] * "\n\t"}", { :member => member.inspect }) unless e.to_s.include?("Timeout")
              Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"        
            end
            Rails.logger.info "    ... took #{Time.zone.now - tz}seconds for member ##{member.id}"
          end
        end
      end
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
          Auditory.report_issue("Member:mailchimp_member", 'Mailchimp not configured correctly', { :club => self.club.inspect, :member => self.inspect })
          nil
        end
      end

      def skip_mailchimp_sync!
        @skip_mailchimp_sync = true
      end
    end
  end
end