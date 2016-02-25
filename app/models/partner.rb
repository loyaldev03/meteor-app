class Partner < ActiveRecord::Base
  has_many :domains, dependent: :delete_all
  has_many :clubs, dependent: :destroy

  accepts_nested_attributes_for :domains, limit: 1

  acts_as_paranoid
  validates :name , presence: true, name_is_not_admin: true, format: /\A[a-zA-Z ]+\z/,
                    uniqueness: { scope: :deleted_at }
  validates :prefix, presence: true, prefix_is_not_admin: true, format: /\A[a-zA-Z ]+\z/,
                    uniqueness: { scope: :deleted_at }, 
                    length: { maximum: 40, too_long: 'Pick a shorter prefix' }

  def self.datatable_columns
    ['id', 'prefix', 'name', 'contract_uri', 'website_url' ]
  end
  
end
