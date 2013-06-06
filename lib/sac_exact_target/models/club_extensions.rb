module SacExactTarget
  module ClubExtensions
    def self.included(base)
      # base.extend ClassMethods
      base.send :include, InstanceMethods
    end

    module InstanceMethods
      def exact_target
        unless [self.exact_target_business_unit_id, self.exact_target_member_list_id, self.exact_target_prospect_list_id].all?
          raise 'no exact target information configured'
        end
      end

      def exact_target_sync?
        [self.exact_target_business_unit_id, self.exact_target_member_list_id, self.exact_target_prospect_list_id].none?(&:blank?)
      end      
    end
  end
end