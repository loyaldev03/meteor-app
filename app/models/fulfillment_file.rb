class FulfillmentFile < ActiveRecord::Base
  # attr_accessible :title, :body
  has_and_belongs_to_many :fulfillments
  belongs_to :agent
  belongs_to :club

  state_machine :status, :initial => :in_process do
    event :processed do
      transition :in_process => :sent
    end
    
    #First status. fulfillment file was created
    state :in_process
    #Manually set through CS. Every fulfillment inside was processed.
    state :sent 
  end

end
