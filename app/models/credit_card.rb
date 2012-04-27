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


  # refs #17832
  def self.card_expired_rule(cc_year_exp)
    #6 Days Later if not successful = (+3), 3/2014
    #6 Days Later if not successful = (+2), 3/2013
    #6 Days Later if not successful = (+4) 3/2015
    #6 Days Later if not successful = (+1) 3/2012
    if cc_year_exp.to_i < Date.today.year
      case self.times
        when 1
          new_year_exp=cc_year_exp.to_i + 3
        when 2
          new_year_exp=cc_year_exp.to_i + 2
        when 3
          new_year_exp=cc_year_exp.to_i + 4
        when 4
          new_year_exp=cc_year_exp.to_i + 1
        else
          new_year_exp=cc_year_exp
      end  
    else
      new_year_exp=cc_year_exp
    end
    new_year_exp
  end
  
end
