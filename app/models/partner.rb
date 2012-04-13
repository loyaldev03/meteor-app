class Partner < ActiveRecord::Base
  has_many :domains

  attr_accessible :contract_uri, :deleted_at, :description, :name, :prefix, :website_url, :logo
  
  acts_as_paranoid
  validates_presence_of :name, :prefix
  validates_uniqueness_of :prefix, :name

  has_attached_file :logo, :path => ":rails_root/public/system/:attachment/:id/:style/:filename", :url => "/system/:attachment/:id/:style/:filename"

end
