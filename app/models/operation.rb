class Operation < ActiveRecord::Base
  belongs_to :created_by, :class_name => 'Agent', :foreign_key => 'created_by_id'
  belongs_to :resource, :polymorphic => true
  belongs_to :member
  attr_accessible :description, :operation_date, :resource, :notes, :operation_type

  before_create :set_operation_date_if_nil

  validates :description, :presence => true

  def self.datatable_columns
    ['id', 'operation_date', 'description', 'notes']
  end

  private
    def set_operation_date_if_nil
      self.operation_date = Time.zone.now if self.operation_date.nil?
    end
end
