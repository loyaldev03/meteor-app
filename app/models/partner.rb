class Partner < ActiveRecord::Base
  has_many :domains, :dependent => :destroy
  has_many :clubs, :dependent => :destroy

  attr_accessible :contract_uri, :deleted_at, :description, :name, :prefix, 
    :website_url, :logo, :domains_attributes

  accepts_nested_attributes_for :domains, :limit => 1

  acts_as_paranoid
  validates :name , :presence => true, :uniqueness => true, :name_is_not_admin => true
  validates :prefix, :presence => true, :uniqueness => true, :prefix_is_not_admin => true

  def self.datatable_columns
    ['id', 'prefix', 'name', 'contract_uri', 'website_url' ]
  end
  
end
