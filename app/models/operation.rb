class Operation < ActiveRecord::Base
  belongs_to :created_by, -> { with_deleted }, class_name: 'Agent', foreign_key: 'created_by_id'
  belongs_to :resource, polymorphic: true
  belongs_to :user

  before_create :set_operation_date_if_nil

  validates :description, presence: true

  scope :is_visible, -> { where("operation_type < 5000") }


  def self.datatable_columns
    ['id', 'operation_date', 'description']
  end

  private
    def set_operation_date_if_nil
      self.operation_date = Time.zone.now if self.operation_date.nil?
    end
end
