class MemberGroupType < Enumeration
  has_many :members
  belongs_to :club

  def to_s
    name
  end
  
end

