class User < ActiveRecord::Base
  include Extensions::UUID

  attr_accessible :ip_address, :user_agent
  
  belongs_to :domain

end
