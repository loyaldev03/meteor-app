class Domain < ActiveRecord::Base
  belongs_to :partner
  belongs_to :club

  attr_accessible :data_rights, :deleted_at, :description, :hosted, :partner, :url

  acts_as_paranoid
end
