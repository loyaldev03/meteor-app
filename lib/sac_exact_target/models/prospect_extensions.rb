module SacExactTarget
  module ProspectExtensions
    def self.included(base)
      base.send :extend, ClassMethods
      base.send :include, InstanceMethods
    end

    module ClassMethods
      def sync_prospects_to_exact_target
        club_base = Club.exact_target_related
        club_base.each do |club|
          tzc = Time.zone.now
          base = club.prospects.where("need_exact_target_sync = 1")
          Rails.logger.info " *** [#{I18n.l(Time.zone.now, :format =>:dashed)}] Starting mkt_tools:sync_prospects_to_exact_target, processing #{base.count} prospects for club #{club.id}"
          base.find_in_batches do |group|
            group.each_with_index do |prospect,index|
              tz = Time.zone.now
              begin
                Rails.logger.info "  *[#{index+1}] processing prospect ##{prospect.id}"
                prospect.exact_target_after_create_sync_to_remote_domain(club) if defined?(SacExactTarget::ProspectModel)
              rescue Exception => e
                Airbrake.notify(:error_class => "ExactTarget::ProspectSync", :error_message => "#{e.to_s}\n\n#{$@[0..9] * "\n\t"}", :parameters => { :member => prospect.inspect })
                Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
              end
              Rails.logger.info "    ... took #{Time.zone.now - tz} for prospect ##{prospect.id}"
            end
          end
          Rails.logger.info "    ... took #{Time.zone.now - tzc} for club ##{club.id}"
        end
      end
    end   

    module InstanceMethods
      def exact_target_prospect
        @exact_target_prospect ||= SacExactTarget::ProspectModel.new self
      end

      def exact_target_after_create_sync_to_remote_domain(club = nil)
        exact_target_sync_to_remote_domain(club) unless exact_target_prospect.nil?
      end

      def exact_target_sync_to_remote_domain(club = nil)
        time_elapsed = Benchmark.ms do
          exact_target_prospect.save!(club)
        end
        logger.info "SacExactTarget::sync took #{time_elapsed}ms"
      rescue Exception => e
        Auditory.report_issue("Prospect:sync", e, { :prospect => self.inspect }) unless e.to_s.include?("Timeout")
        raise e
      end
    end
  end
end