class Auditory
  # current_agent : if null will find the "batch" agent used on scripts.
  # object : the object added/modify/deleted by agent
  # description : custom message 
  # member : member that must show this operation (only for operations that are related to members: e.g. CC management, Emails)
  # operation_type : operation type used by reporting/web to group operations
  # operation_date : date when the operation related was done. If this value is nil we save that operation with Time.zone.now
  def self.audit(current_agent, object, description, member = nil, operation_type = Settings.operation_types.others, operation_date = Time.zone.now, notes = nil)
    @batch_agent ||= Agent.find_by_email('batch@xagax.com') if current_agent.nil?
    o = Operation.new :operation_date => operation_date, 
      :resource => object, :description => description, :operation_type => operation_type
    o.created_by_id = (current_agent.nil? ? @batch_agent.id : current_agent.id)
    o.notes = notes
    o.member = member
    o.save!
  rescue Exception => e
    Rails.logger.error " * * * * * CANT SAVE OPERATION #{e}"
  end
  
  def self.report_issue(error = "Special Error", message = '', params = {}, add_backtrace = true)
    unless ["test","development"].include? Rails.env  
    # Airbrake.notify(:error_class   => error, :error_message => message, :parameters => params)
      comment = message.to_s
      comment = comment + "\n\n\n Parameters:\n" + params.collect{|k,v| "#{k}: #{v}" }.join("\n")
      comment = comment + "\nBacktrace:\n " + caller.join("\n").to_s if add_backtrace

      file_url = "/tmp/error_description_#{Time.zone.now.to_i}.txt"
      temp = File.open(file_url, 'w+')
      temp.write comment
      temp.close

      ticket = ZendeskAPI::Ticket.new(ZENDESK_API_CLIENT,
        :subject => "[#{Rails.env}] #{error}",
        :comment => { :value => comment.truncate(10000) },
        :submitter_id => ZENDESK_API_CLIENT.current_user.id,
        :assignee_id => ZENDESK_API_CLIENT.current_user.id,
        :type => "incident",
        :tags => (Rails.env == 'production' ? "support-ruby-production" : "support-ruby" ),
        :priority => (Rails.env == 'production' ? "urgent" : "normal" ))

      ticket.comment.uploads << file_url
      ticket.save
      File.delete(file_url)
    end
  end
end