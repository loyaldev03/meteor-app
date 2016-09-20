module FulfillmentFiles
  class SendEmailWithFileJob < ActiveJob::Base
    queue_as :email_queue

    def perform(fulfillment_file_id:, only_in_progress:)
      fulfillment_file = FulfillmentFile.find fulfillment_file_id
      fulfillment_file.send_email_with_file only_in_progress
    end
  end
end