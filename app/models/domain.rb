class Domain < ActiveRecord::Base
  belongs_to :partner
  belongs_to :club

  attr_accessible :data_rights, :deleted_at, :description, :hosted, :partner, :url, :club_id
  
  # this validation is comented because it does not works the nested form
  # of partner. TODO: can we add this validation without problems?
  # validates :partner, :presence => true 
  validates :url, :presence => true 

  acts_as_paranoid
end
