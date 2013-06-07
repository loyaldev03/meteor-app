module SacExactTarget
  module ClubExtensions
    def self.included(base)
      base.send :include, InstanceMethods
    end

    module InstanceMethods
      def exact_target
        if not self.marketing_tool_attributes or not [ self.marketing_tool_attributes[:et_bussines_unit], self.marketing_tool_attributes[:et_prospect_list], self.marketing_tool_attributes[:et_members_list] ].all?
          raise 'no exact target information configured'
        end
      end  
    end
  end
end