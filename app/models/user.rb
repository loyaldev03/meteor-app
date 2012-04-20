class User < ActiveRecord::Base
  # attr_accessible :title, :body
  belongs_to :domain
end
