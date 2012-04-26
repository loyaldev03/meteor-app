class Auditory
  def self.audit(current_agent, object, description, member = nil)
    begin
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