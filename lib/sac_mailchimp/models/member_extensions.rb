module SacMailchimp
	module MemberExtensions
    def self.included(base)
      base.send :extend, ClassMethods
      base.send :include, InstanceMethods
    end

    module ClassMethods
      def sync_members_to_mailchimp
        base = User.where("(need_sync_to_marketing_client = 1 OR (marketing_client_synced_status = 'error' AND marketing_client_last_sync_error LIKE ? AND DATE(marketing_client_last_sync_error_at) = ?)) AND club_id IN (?)", "%#{SacMailchimp::MULTIPLE_SIGNED_ERROR_MESSAGE}%", (Time.current - 4.days).to_date, Club.mailchimp_related.pluck(:id))
        Rails.logger.info " *** [#{I18n.l(Time.zone.now, :format =>:dashed)}] Starting members:sync_members_to_mailchimp, processing #{base.count} members"
        exception_count = 0
        base.find_in_batches do |group|
          group.each_with_index do |member, index|
            tz = Time.zone.now
            begin
              Rails.logger.info "  *[#{index+1}] processing member ##{member.id}"
              member.marketing_tool_sync
            rescue StandardError
              Rails.logger.error "    [!] Mailchimp::MemberSync failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
              exception_count += 1
            end
            Rails.logger.info "    ... took #{Time.zone.now - tz}seconds for member ##{member.id}"
          end
        end
        Auditory.report_issue('Mailchimp::UserSync: Unexpected errors. Check logs.', nil, exception_count: exception_count) if exception_count > 0
      end
    end

    module InstanceMethods

      def mailchimp_sync_to_remote_domain!
        return if @skip_mailchimp_sync
        time_elapsed = Benchmark.ms do
          mailchimp_member.save!
        end
        logger.info "SacMailchimp::sync took #{time_elapsed}ms"
      rescue Exception => e
        SacMailchimp::report_error("Member:mailchimp_sync", e, self)
      end

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