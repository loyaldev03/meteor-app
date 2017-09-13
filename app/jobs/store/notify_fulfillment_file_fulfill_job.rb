module Store
  class NotifyFulfillmentFileFulfillJob < ActiveJob::Base
    queue_as :store

    def perform(fulfillment_file)
      fulfillments_with_errors = fulfillment_file.fulfillments.where.not(sync_result: 'success').select(:fulfillment_id, :user_id, :sync_result)
      success_count = fulfillment_file.fulfillments.where(sync_result: 'success').count
      Auditory.management_stock_notification('Error while notifying fulfillment send to the Store', "There have been some errors while notifying some fulfillment's send in fulfillment file ID##{fulfillment_file.id}. Details are below:", fulfillments_with_errors.map{|x| "Fulfillment ID##{x.fulfillment_id}: #{x.sync_result}"}) if fulfillments_with_errors.any?
      StoreNotifier.fulfillment_file_send_results(fulfillment_file.agent_id, fulfillment_file.id, success_count, fulfillments_with_errors.map{|x| x[:fulfillment_id]}).deliver_later!
    end
  end
end