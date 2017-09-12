class StoreNotifier < ActionMailer::Base
  default from: Settings.platform_email
  default bcc: Settings.platform_admins_email
  layout 'mailer'

  def fulfillment_file_send_results(agent_id, fulfillment_file_id, success_count, fulfillments_ids_with_errors)
    agent = Agent.find(agent_id)
    @fulfillment_file = FulfillmentFile.find(fulfillment_file_id)
    @success_count = success_count 
    @errors = Fulfillment.where(id: fulfillments_ids_with_errors).pluck(:id, :user_id, :sync_result).map{ |id, user_id, sync_result| { user_id: user_id, fulfillment_id: id, error: sync_result} }
    mail to: agent.email,
        content_type: 'text/html',
        subject: "#{I18n.l(Time.current, :format => :default )} - Fulfillment File Store synchronization results"
  end

end