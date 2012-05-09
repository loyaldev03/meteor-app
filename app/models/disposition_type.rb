class DispositionType < Enumeration
  has_many :member_notes
  belongs_to :club

  def to_s
    name
  end
end
