module SacExactTarget
  module MemberExtensions
    def self.included(base)
      base.send :include, InstanceMethods
    end

    module InstanceMethods
      def exact_target_after_create_sync_to_remote_domain
        exact_target_sync_to_remote_domain unless exact_target_member.nil?
      end

      def exact_target_sync_to_remote_domain
        return if @skip_exact_target_sync
        time_elapsed = Benchmark.ms do
          exact_target_member.save!
        end
        logger.info "SacExactTarget::sync took #{time_elapsed}ms"
      rescue Exception => e
        Auditory.report_issue("Member:sync", e, { :member => self.inspect })
      end

      def exact_target_sync?
        self.club.exact_target_sync?
      end

      def exact_target_member
        @exact_target_member ||= if !self.exact_target_sync?
          nil
        else
          SacExactTarget::MemberModel.new self
        end
      end

      def skip_exact_target_sync!
        @skip_exact_target_sync = true
      end
    end
  end
end