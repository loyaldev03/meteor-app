class MemberNote < ActiveRecord::Base
  attr_accessible :communication_type, :created_by_id, :member_id, :note_type
  belongs_to :member

  # TODO: this must be on application yml.
  NOTE_TYPE = [ '', '' ]
  # TODO: this must be on application yml.
  COMMUNICATION_TYPE = [ '', '' ]

end
