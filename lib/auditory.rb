class Auditory
  # current_agent : if null will find the "batch" agent used on scripts.
  # object : the object added/modify/deleted by agent
  # description : custom message 
  # member : member that must show this operation (only for operations that are related to members: e.g. CC management, Emails)
  # operation_type : operation type used by reporting/web to group operations
  # operation_date : date when the operation related was done. If this value is nil we save that operation with Time.zone.now
  def self.audit(current_agent, object, description, member = nil, operation_type = Settings.operation_types.others, operation_date = Time.zone.now)
    begin
      current_agent = Agent.find_by_email('batch@xagax.com') if current_agent.nil?
      o = Operation.new :operation_date => operation_date, 
        :resource => object, :description => description, :operation_type => operation_type
      o.created_by_id = (current_agent.nil? ? nil : current_agent.id)
      o.member = member
      o.save!
    rescue Exception => e
      Rails.logger.error " * * * * * CANT SAVE OPERATION #{e}"
    end
  end
  def self.add_redmine_ticket(error = "Special Error", message = '', params = {})
    Airbrake.notify(:error_class   => error, :error_message => "#{error}: #{message}", :parameters    => params)    
  end
end