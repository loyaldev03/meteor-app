class FulfillmentFile < ActiveRecord::Base
  # attr_accessible :title, :body
  has_and_belongs_to_many :fulfillments
  belongs_to :agent
  belongs_to :club

  state_machine :status, :initial => :in_process do
    after_transition :in_process => :sent, :do => :mark_fulfillments_as_sent

    event :processed do
      transition :in_process => :sent
    end
    
    #First status. fulfillment file was created
    state :in_process
    #Manually set through CS. Every fulfillment inside was processed.
    state :sent 
  end

  def dates
    self.all_times ? "All times" : "from #{self.initial_date} to #{self.end_date}"
  end

  def fulfillments_processed
    [ fulfillments.where_in_process.count, fulfillments.count ].join(' / ')
  end

  def mark_fulfillments_as_sent
    self.fulfillments.where_in_process.each { |x| x.set_as_sent! }
  end

end
