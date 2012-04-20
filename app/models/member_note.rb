class MemberNote < ActiveRecord::Base
  attr_accessible :communication_type, :created_by_id, :member_id, :note_type
  belongs_to :created_by, :class_name => 'Agent', :foreign_key => 'created_by_id'
  belongs_to :member

end
