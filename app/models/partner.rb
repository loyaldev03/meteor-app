class Partner < ActiveRecord::Base
  has_many :domains
  has_many :clubs

  attr_accessible :contract_uri, :deleted_at, :description, :name, :prefix, :website_url, :logo
  
  acts_as_paranoid
  validates :name , :presence => true, :uniqueness => true
  validates :prefix, :presence => true, :uniqueness => true, :prefix_admin => true

  has_attached_file :logo, :path => ":rails_root/public/system/:attachment/:id/:style/:filename", 
                           :url => "/system/:attachment/:id/:style/:filename",
                           :style => {:thumb=> "100x100#", :small  => "150x150>"}
                           
end
