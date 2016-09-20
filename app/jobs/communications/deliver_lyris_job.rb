module Communications
  class DeliverLyrisJob < ActiveJob::Base
    queue_as :lyris_email

    def perform(communication_id:)
      communication = Communication.find communication_id
      communication.deliver_lyris
    end
  end
end