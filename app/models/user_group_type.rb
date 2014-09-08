class UserGroupType < Enumeration
  has_many :users
  belongs_to :club

  def to_s
    name
  end
  
end

