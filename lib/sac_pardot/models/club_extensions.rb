module Pardot
  module ClubExtensions
    def self.included(base)
      # base.extend ClassMethods
      base.send :include, InstanceMethods
    end

    module InstanceMethods
      def pardot
        unless @pardot_client
          unless [self.pardot_email, self.pardot_password, self.pardot_user_key].all?
            raise 'no pardot credentials configured'
          end
          @pardot_client = Pardot::Client.new self.pardot_email, self.pardot_password, self.pardot_user_key
        end
        @pardot_client
      end
    end
  end
end