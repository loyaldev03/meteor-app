class CommunicationType < Enumeration
  has_many :member_notes

  def to_s
    name
  end
end
