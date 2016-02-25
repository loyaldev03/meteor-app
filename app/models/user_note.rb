class UserNote < ActiveRecord::Base
  belongs_to :created_by, -> { with_deleted }, class_name: 'Agent', foreign_key: 'created_by_id'
  belongs_to :user
  belongs_to :disposition_type
  belongs_to :communication_type
  
end
