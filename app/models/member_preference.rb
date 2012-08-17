class MemberPreference < ActiveRecord::Base
  include Extensions::UUID

  belongs_to :member

  attr_accessible  :member_id, :club_id, :param, :value
end
