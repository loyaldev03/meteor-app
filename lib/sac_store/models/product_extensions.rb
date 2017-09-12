module SacStore
  module ProductExtensions
    def self.included(base)
      base.send :include, InstanceMethods
    end

    module InstanceMethods
      def store_product
        @store_product ||= if club.has_store_configured?
          SacStore::ProductModel.new self
        else
          nil
        end
      end
    end
  end
end