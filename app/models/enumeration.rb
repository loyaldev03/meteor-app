class Enumeration < ActiveRecord::Base
  default_scope { where("visible = true").order("#{Enumeration.table_name}.position ASC") }
  belongs_to :club

  acts_as_paranoid
  acts_as_list scope: [:type, :club_id]
  
#  validates_as_paranoid #FIXME
  validates_presence_of :name
#  validates_uniqueness_of_without_deleted :name, :scope => [:type, :club_id] #FIXME
  
end
