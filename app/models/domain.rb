class Domain < ActiveRecord::Base
  belongs_to :partner
  attr_accessible :data_rights, :deleted_at, :description, :hosted, :partner, :url

  acts_as_paranoid
end
