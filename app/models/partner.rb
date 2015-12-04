class Partner < ActiveRecord::Base
  has_many :domains, dependent: :delete_all
  has_many :clubs, dependent: :destroy

  attr_accessible :contract_uri, :deleted_at, :description, :name, :prefix, 
    :website_url, :logo, :domains_attributes

  accepts_nested_attributes_for :domains, limit: 1

  acts_as_paranoid
  validates :name , presence: true, name_is_not_admin: true, format: /\A[a-zA-Z ]+\z/,
                    uniqueness: { scope: :deleted_at }
  validates :prefix, presence: true, prefix_is_not_admin: true, format: /\A[a-zA-Z ]+\z/,
                    uniqueness: { scope: :deleted_at }

  def self.datatable_columns
    ['id', 'prefix', 'name', 'contract_uri', 'website_url' ]
  end
  
end
