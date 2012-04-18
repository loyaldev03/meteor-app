class CreditCard < ActiveRecord::Base
  belogns_to :member

  attr_accessible :active, :encrypted_number, :expire_month, :expire_year

  attr_encrypted :encrypted_number, :key => :encryption_key, :encode => true, :algorithm => 'bf'

  def encryption_key
    "reibel3y5estrada8"
  end 
  
end
