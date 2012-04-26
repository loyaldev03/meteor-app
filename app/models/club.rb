class Club < ActiveRecord::Base
  belongs_to :partner
  has_many :domains
  has_many :terms_of_memberships
  has_many :members
  has_many :payment_gateway_configurations
  
  attr_accessible :description, :name, :logo

  acts_as_paranoid

  validates :partner_id, :presence => true
  validates :name, :presence => true

  has_attached_file :logo, :path => ":rails_root/public/system/:attachment/:id/:style/:filename", 
                           :url => "/system/:attachment/:id/:style/:filename",
                           :styles => {:thumb => "100x100#", :small  => "150x150>"}

  def full_name
    [ partner.name, name ].join(' ')
  end

end
