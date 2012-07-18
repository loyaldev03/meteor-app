class MemberPreference < ActiveRecord::Base
  include Extensions::UUID
  attr_accessible  :member_id, :club_id, :param, :value
end
