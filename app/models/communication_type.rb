class CommunicationType < Enumeration
  has_many :user_notes

  def to_s
    name
  end
end
