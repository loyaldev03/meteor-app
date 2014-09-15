class UserAdditionalData < ActiveRecord::Base
  belongs_to :user

  attr_accessible  :user_id, :club_id, :param, :value
end
