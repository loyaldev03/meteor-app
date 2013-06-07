module SacExactTarget
  module MemberExtensions
    def self.included(base)
      base.send :include, InstanceMethods
    end

    module InstanceMethods
      def exact_target_sync?
        self.club.exact_target_sync?
      end

      def exact_target_member
        @exact_target_member ||= if !self.exact_target_sync?
          nil
        else
          SacExactTarget::Member.new self
        end
      end

      def skip_exact_target_sync!
        @skip_exact_target_sync = true
      end
    end
  end
end