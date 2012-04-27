class Auditory
  # current_agent : if null will find the "batch" agent used on scripts.
  # object : the object added/modify/deleted by agent
  # description : custom message 
  # member : member that must show this operation (only for operations that are related to members: e.g. CC management, Emails)
  def self.audit(current_agent, object, description, member = nil)
    begin
      current_agent = Agent.find_by_email('batch@xagax.com.ar') if current_agent.nil?
      o = Operation.new :created_by_id => current_agent.id, :operation_date => DateTime.now, 
        :resource => object, :description => description
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