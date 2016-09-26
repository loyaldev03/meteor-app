module Communications
  class DeliverMandrillJob < ActiveJob::Base
    queue_as :mandrill_email

    def perform(communication_id:)
      communication = Communication.find communication_id
      communication.deliver_mandrill
    end
  end
end