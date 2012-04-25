class Auditory
  def self.audit(current_agent, object, description)
    begin
      o = Operation.new :created_by_id => current_agent.id, :operation_date => DateTime.now, 
        :resource => object, :description => description
      o.save!
    rescue Exception => e
      logger.error " * * * * * CANT SAVE OPERATION #{e}"
    end
  end
end