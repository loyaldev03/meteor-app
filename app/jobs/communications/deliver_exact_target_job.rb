module Communications
  class DeliverExactTargetJob < ActiveJob::Base
    queue_as :exact_target_email

    def perform(communication_id:)
      communication = Communication.find communication_id 
      communication.deliver_exact_target
    end
  end
end