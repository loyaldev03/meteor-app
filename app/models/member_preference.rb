class MemberPreference < ActiveRecord::Base

  belongs_to :member

  attr_accessible  :member_id, :club_id, :param, :value
end
