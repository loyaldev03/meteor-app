module SacExactTarget
  module ProspectExtensions
    def self.included(base)
      base.send :extend, ClassMethods
      base.send :include, InstanceMethods
    end

    module ClassMethods
      def sync_prospects_to_exact_target
        index = 0
        base = Prospect.where(" exact_target_sync_result IS NULL ")
        Rails.logger.info " *** [#{I18n.l(Time.zone.now, :format =>:dashed)}] Starting mkt_tools:sync_prospects_to_exact_target, processing #{base.count} prospects"
        base.find_in_batches do |group|
          group.each do |prospect|
            tz = Time.zone.now
            begin
              index = index+1
              Rails.logger.info "  *[#{index}] processing prospect ##{prospect.id}"
              prospect.marketing_tool_sync
            rescue Exception => e
              Airbrake.notify(:error_class => "ExactTarget::ProspectSync", :error_message => "#{e.to_s}\n\n#{$@[0..9] * "\n\t"}", :parameters => { :member => prospect.inspect })
              Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
            end
            Rails.logger.info "    ... took #{Time.zone.now - tz} for prospect ##{prospect.id}"
          end
        end
      end
    end   

    module InstanceMethods
      def exact_target_prospect
        @exact_target_prospect ||= if !self.club.exact_target_sync?
          nil
        else
          SacExactTarget::ProspectModel.new self
        end
      end

      def exact_target_after_create_sync_to_remote_domain
        exact_target_sync_to_remote_domain unless exact_target_prospect.nil?
      end

      def exact_target_sync_to_remote_domain
        time_elapsed = Benchmark.ms do
          exact_target_prospect.save!
        end
        logger.info "SacExactTarget::sync took #{time_elapsed}ms"
      rescue Exception => e
        Auditory.report_issue("Prospect:sync", e, { :prospect => self.inspect })
      end

    end
  end
end