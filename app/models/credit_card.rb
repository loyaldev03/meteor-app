class CreditCard < ActiveRecord::Base
  belongs_to :member
  has_many :transactions

  attr_accessible :active, :number, :expire_month, :expire_year

  attr_encrypted :number, :key => Settings.cc_encryption_key, :encode => true, :algorithm => 'bf'

  validates :expire_month, :numericality => { :only_integer => true, :greater_than => 0, :less_than_or_equal_to => 12 }
  validates :expire_year, :numericality => { :only_integer => true, :greater_than => 2000 } 

  def accepted_on_billing
    update_attribute :last_successful_bill_date, DateTime.now
  end
  
end
