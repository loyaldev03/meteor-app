class Partner < ActiveRecord::Base
  has_many :domains
  has_many :clubs
  has_many :members

  attr_accessible :contract_uri, :deleted_at, :description, :name, :prefix, 
    :website_url, :logo, :domains_attributes

  accepts_nested_attributes_for :domains, :limit => 1

  acts_as_paranoid
  validates :name , :presence => true, :uniqueness => true, :name_is_not_admin => true
  validates :prefix, :presence => true, :uniqueness => true, :prefix_is_not_admin => true

  has_attached_file :logo, :path => ":rails_root/public/system/:attachment/:id/:style/:filename", 
                           :url => "/system/:attachment/:id/:style/:filename",
                           :style => {:thumb=> "100x100#", :small  => "150x150>"}



end
