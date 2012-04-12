class Domain < ActiveRecord::Base
  attr_accessible :data_rights, :deleted_at, :description, :hosted, :partner_id, :url

  acts_as_paranoid
end
