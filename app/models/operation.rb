class Operation < ActiveRecord::Base
  belongs_to :created_by, :class_name => 'Agent', :foreign_key => 'created_by_id'
  belongs_to :resource, :polymorphic => true
  belongs_to :member
  attr_accessible :description, :created_by_id, :operation_date, :resource, :notes, :operation_type

  before_create :set_operation_date_if_nil

  def self.datatable_columns
    ['operation_date', 'description', 'notes']
  end

  private
    def set_operation_date_if_nil
      self.operation_date = DateTime.now if self.operation_date.nil?
    end
end
