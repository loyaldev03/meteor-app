class MemberNote < ActiveRecord::Base
  attr_accessible :communication_type_id, :created_by_id, :member_id, :note_type, :description
  belongs_to :created_by, :class_name => 'Agent', :foreign_key => 'created_by_id'
  belongs_to :member
  belongs_to :disposition_type
  belongs_to :communication_type

end
