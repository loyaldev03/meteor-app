class DispositionType < Enumeration
  has_many :member_notes
  belongs_to :club

  validates :name, uniqueness: {scope: :club_id}

  def to_s
    name
  end

  def self.datatable_columns
  	['id', 'name']
  end
end
