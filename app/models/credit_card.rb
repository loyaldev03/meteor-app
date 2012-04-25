class CreditCard < ActiveRecord::Base
  belongs_to :member
  has_many :transactions

  attr_accessible :active, :encrypted_number, :expire_month, :expire_year

  attr_encrypted :number, :key => :encryption_key, :encode => true, :algorithm => 'bf'

  validates :expire_month, :numericality => { :only_integer => true, :greater_than => 0, :less_than_or_equal_to => 12 }
  validates :expire_year, :numericality => { :only_integer => true, :greater_than => 2000 } 

  def encryption_key
    "reibel3y5estrada8"
  end 
  
end
