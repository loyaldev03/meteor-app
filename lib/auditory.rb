class Auditory
  # current_agent : if null will find the "batch" agent used on scripts.
  # object : the object added/modify/deleted by agent
  # description : custom message 
  # member : member that must show this operation (only for operations that are related to members: e.g. CC management, Emails)
  # operation_type : operation type used by reporting/web to group operations
  def self.audit(current_agent, object, description, member = nil, operation_type = Settings.operation_types.others)
    begin
      current_agent = Agent.find_by_email('batch@xagax.com') if current_agent.nil?
      o = Operation.new :operation_date => DateTime.now, 
        :resource => object, :description => description, :operation_type => operation_type
      o.created_by_id = (current_agent.nil? ? nil : current_agent.id)
      o.member = member
      o.save!
    rescue Exception => e
      Rails.logger.error " * * * * * CANT SAVE OPERATION #{e}"
    end
  end
  def self.add_redmine_ticket
     #TODO: #18775
  end
end