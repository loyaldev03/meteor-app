module SacMailchimp
	module ProspectExtensions
    def self.included(base)
      base.send :extend, ClassMethods
      base.send :include, InstanceMethods
    end

    module ClassMethods
      def sync_prospects_to_mailchimp
        club_base = Club.mailchimp_related
        club_base.each do |club|
          prospect_club_count = club.prospects.where("need_sync_to_marketing_client = 1").count
          Rails.logger.info " *** [#{I18n.l(Time.zone.now, :format =>:dashed)}] Starting mkt_tools:sync_prospects_to_mailchimp, processing #{prospect_club_count} prospects for club #{club.id}"
          tzc             = Time.zone.now
          base            = club.prospects.where('need_sync_to_marketing_client = 1').order('created_at ASC').limit(1000)
          index           = 0
          exception_count = 0
          while not base.empty? do
            base.each do |prospect|
              tz = Time.zone.now
              begin
                Rails.logger.info "  *[#{index+1}] processing prospect ##{prospect.id}"
                prospect.mailchimp_after_create_sync_to_remote_domain(club) if defined?(SacMailchimp::ProspectModel)
              rescue StandardError
                prospect.update_attribute :need_sync_to_marketing_client, 0
                Rails.logger.error "    [!] Mailchimp::ProspectSync failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
                exception_count += 1
              end
              Rails.logger.info "    ... took #{Time.zone.now - tz}seconds for prospect ##{prospect.id}"
              index += 1
            end
            base = club.prospects.where('need_sync_to_marketing_client = 1').order('created_at ASC').limit(1000)
          end
          Rails.logger.info "    ... took #{Time.zone.now - tzc}seconds for club ##{club.id}"
        end
        Auditory.report_issue('Mailchimp::ProspectSync: Unexpected errors. Check logs. Check logs.', nil, exception_count: exception_count) if exception_count > 0
      end
    end

    module InstanceMethods
      def mailchimp_after_create_sync_to_remote_domain(club = nil)
        mailchimp_sync_to_remote_domain(club) unless mailchimp_prospect.nil?
      end

      def mailchimp_sync_to_remote_domain(club = nil)
        return if @skip_mailchimp_sync
        time_elapsed = Benchmark.ms do
          mailchimp_prospect.save!(club)
        end
        logger.info "SacMailchimp::sync took #{time_elapsed}ms"
      rescue Exception => e
        SacMailchimp::report_error('Prospect:mailchimp_sync', e, self)
      end

      def mailchimp_sync?
        self.club.mailchimp_sync?
      end

      def mailchimp_prospect
        if self.club.mailchimp_sync?
          SacMailchimp.config_integration(self.club.marketing_tool_attributes["mailchimp_api_key"])
          @mailchimp_prospect ||= if !self.mailchimp_sync?
            nil
          else
            SacMailchimp::ProspectModel.new self
          end
        else
          SacMailchimp::report_error('Prospect:mailchimp_prospect', 'Mailchimp not configured correctly', self, false)
          nil
        end
      end

      def skip_mailchimp_sync!
        @skip_mailchimp_sync = true
      end
    end
  end
end