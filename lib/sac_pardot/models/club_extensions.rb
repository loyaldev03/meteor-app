module Pardot
  module ClubExtensions
    def self.included(base)
      base.send :include, InstanceMethods
    end

    module InstanceMethods
      def pardot
        unless @pardot_client
          unless [self.marketing_tool_attributes['pardot_email'], self.marketing_tool_attributes['pardot_password'], self.marketing_tool_attributes['pardot_user_key']].all?
            raise 'no pardot credentials configured'
          end
          @pardot_client = Pardot::Client.new self.marketing_tool_attributes['pardot_email'], self.marketing_tool_attributes['pardot_password'], self.marketing_tool_attributes['pardot_user_key']
        end
        @pardot_client
      end
    end
  end
end