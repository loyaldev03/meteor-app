class Partner < ActiveRecord::Base
  attr_accessible :contract_uri, :deleted_at, :description, :name, :prefix, :website_url

 # acts_as_paranoid

 # attr_protected :prefix

 # validates :prefix, :uniqueness => :true, :presence => :true

 has_attached_file :logo, :styles => { :medium => "300x300>", :thumb => "100x100>" }

end
