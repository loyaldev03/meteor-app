class Partner < ActiveRecord::Base
  has_many :domains
  has_many :clubs

  attr_accessible :contract_uri, :deleted_at, :description, :name, :prefix, 
    :website_url, :logo, :domains_attributes

  accepts_nested_attributes_for :domains, :limit => 1

  acts_as_paranoid
  validates :name , :presence => true, :uniqueness => true, :name_is_not_admin => true
  validates :prefix, :presence => true, :uniqueness => true, :prefix_is_not_admin => true

end
