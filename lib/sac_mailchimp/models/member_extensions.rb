module SacMailchimp
	module MemberExtensions
    def self.included(base)
      base.send :extend, ClassMethods
      base.send :include, InstanceMethods
    end

    module ClassMethods
      def sync_members_to_mailchimp
        base = User.where("need_sync_to_marketing_client = 1 AND club_id in (?)", Club.mailchimp_related.pluck(:id))
        Rails.logger.info " *** [#{I18n.l(Time.zone.now, :format =>:dashed)}] Starting members:sync_members_to_mailchimp, processing #{base.count} members"
        base.find_in_batches do |group|
          group.each_with_index do |member,index|
            tz = Time.zone.now
            begin
              Rails.logger.info "  *[#{index+1}] processing member ##{member.id}"
              member.marketing_tool_mailchimp_sync_without_delay
            rescue Exception => e
              Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"        
              Auditory.report_issue("User Mailchimp synchronization.", e, { :user_id => member.id })
            end
            Rails.logger.info "    ... took #{Time.zone.now - tz}seconds for member ##{member.id}"
          end
        end
      end
    end

    module InstanceMethods
      def mailchimp_after_create_sync_to_remote_domain
        mailchimp_sync_to_remote_domain! if mailchimp_member
      end

      def mailchimp_sync_to_remote_domain!
        return if @skip_mailchimp_sync
        time_elapsed = Benchmark.ms do
          mailchimp_member.save!
        end
        logger.info "SacMailchimp::sync took #{time_elapsed}ms"
      rescue Exception => e
        SacMailchimp::report_error("Member:mailchimp_sync", e, self)
      end

      def marketing_tool_mailchimp_sync
        mailchimp_after_create_sync_to_remote_domain
      end
      handle_asynchronously :marketing_tool_mailchimp_sync, :queue => :mailchimp_sync, priority: 30

      def mailchimp_subscribe
        mailchimp_member.subscribe! if mailchimp_member
      rescue Exception => e
        SacMailchimp::report_error("Member:subscribe", e, self)
      end
      handle_asynchronously :mailchimp_subscribe, :queue => :mailchimp_sync, priority: 30

      def marketing_tool_update_email(former_email)
        time_elapsed = Benchmark.ms do
          mailchimp_member.update_email!(former_email)
        end
        logger.info "SacMailchimp::clean_subscriber took #{time_elapsed}ms"
      rescue Exception => e
        SacMailchimp::report_error("Member:update_email", e, self)
      end
      handle_asynchronously :marketing_tool_update_email, :queue => :mailchimp_sync, priority: 30
      
      def mailchimp_unsubscribe
        time_elapsed = Benchmark.ms do
          mailchimp_after_create_sync_to_remote_domain 
          mailchimp_member.unsubscribe!
        end
        logger.info "SacMailchimp::unsubscribe_subscriber took #{time_elapsed}ms"
      rescue Exception => e
        SacMailchimp::report_error("Member:unsubscribe_subscriber", e, self)
      end
      handle_asynchronously :mailchimp_unsubscribe, :queue => :mailchimp_sync, priority: 30

      def mailchimp_sync?
        self.club.mailchimp_sync?
      end

      def mailchimp_member
        return @mailchimp_member unless @mailchimp_member.nil?
        if not self.club.mailchimp_mandrill_client?
          false
        elsif club.mailchimp_sync?
          SacMailchimp.config_integration(self.club.marketing_tool_attributes["mailchimp_api_key"])
          @mailchimp_member ||= if !self.mailchimp_sync?
            false
          else
            SacMailchimp::MemberModel.new self
          end
        else
          SacMailchimp::report_error('Member:mailchimp_member', 'Mailchimp not configured correctly', self, false)
          false
        end
      end

      def skip_mailchimp_sync!
        @skip_mailchimp_sync = true
      end
    end
  end
end