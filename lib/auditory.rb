class Auditory
  def self.audit!(current_agent, object, description)
    o = Operation.new :created_by_id => current_agent.id, :operation_date => DateTime.now, 
      :resource => object, :description => description
    o.save!
  end
end