module SacExactTarget
  module ProspectExtensions
    def self.included(base)
      base.send :include, InstanceMethods
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