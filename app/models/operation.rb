class Operation < ActiveRecord::Base
  belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by_id'
  belongs_to :resource, :polymorphic => true
  attr_accessible :description

  state_machine :status, :initial => :completed do
    # This operation cant have a button to do generate another operation. 
    # E.g: Billing operation that was already refunded; Update profile
    state :completed
    # Operation that can have a button to do another related operation.
    # E.g: Billing operation that CAN be refunded
    state :modifiable
  end
end
