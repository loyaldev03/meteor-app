class Club < ActiveRecord::Base
  belongs_to :partner
  has_many :domains
  
  attr_accessible :deleted_at, :description, :name, :partner

  acts_as_paranoid
end
