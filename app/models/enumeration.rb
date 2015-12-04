class Enumeration < ActiveRecord::Base
  default_scope { where("visible = true").order("#{Enumeration.table_name}.position ASC") }
  belongs_to :club

  acts_as_paranoid
  acts_as_list scope: [:type, :club_id]
  
  validates :name, presence: true, uniqueness: { scope: [:type, :club_id, :deleted_at] } 
end
