module SacStore
  module FulfillmentExtensions
    def self.included(base)
      base.send :include, InstanceMethods
    end 

    module InstanceMethods
      def store_fulfillment
        @store_fulfillment ||= if club.has_store_configured?
          SacStore::FulfillmentModel.new self
        else
          nil
        end
      end
    end
  end
end