class Operation < ActiveRecord::Base
  belongs_to :created_by, :class_name => 'Agent', :foreign_key => 'created_by_id'
  belongs_to :resource, :polymorphic => true
  belongs_to :member
  attr_accessible :description, :created_by_id, :operation_date, :resource

  before_create :set_operation_date_if_nil

  state_machine :status, :initial => :completed do
    # This operation cant have a button to do generate another operation. 
    # E.g: Billing operation that was already refunded; Update profile
    state :completed
    # Operation that can have a button to do another related operation.
    # E.g: Billing operation that CAN be refunded
    state :modifiable
  end

  private
    def set_operation_date_if_nil
      self.operation_date = DateTime.now if self.operation_date.nil?
    end
end
