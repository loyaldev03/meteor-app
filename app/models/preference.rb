class Preference < ActiveRecord::Base
  belongs_to :preference_group
  validates :name, :preference_group_id, presence: true
  validates :name, uniqueness: { scope: :preference_group }


  def self.datatable_columns
    [ 'name' ]
  end
end