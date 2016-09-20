module Communications
  class DeliverActionMailerJob < ActiveJob::Base
    queue_as :email_queue

    def perform(communication_id:)
      communication = Communication.find communication_id
      communication.deliver_action_mailer
    end
  end
end