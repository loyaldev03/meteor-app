class PreferenceGroup < ActiveRecord::Base
  belongs_to :club, touch: true
  has_many :preferences
  has_and_belongs_to_many :campaigns

  validates :name, :code, :club_id, presence: true
  validates :code, uniqueness: { scope: [:club_id] }

  def self.datatable_columns
    [ 'id', 'name', 'code', 'add_by_default' ]
  end
end