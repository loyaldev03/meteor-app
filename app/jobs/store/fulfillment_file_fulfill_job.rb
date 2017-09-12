module Store
  class FulfillmentFileFulfillJob < ActiveJob::Base
    queue_as :store

    def perform(fulfillment_file, fulfillment_ids)
      fulfillment_file.fulfillments.where(id: fulfillment_ids).each do |fulfillment|
        fulfillment.store_fulfillment.notify_fulfillment_send        
      end
    end

  end
end