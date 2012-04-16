class Club < ActiveRecord::Base
  belongs_to :partner
  has_many :domains
  has_many :payment_gateway_configurations
  has_many :terms_of_memberships
  
  attr_accessible :deleted_at, :description, :name, :partner_id

  acts_as_paranoid

  validates :partner_id, :presence => 'true'

end
