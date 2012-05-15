class CreditCard < ActiveRecord::Base
  belongs_to :member
  has_many :transactions

  attr_accessible :active, :number, :expire_month, :expire_year, :blacklisted

  attr_encrypted :number, :key => Settings.cc_encryption_key, :encode => true, :algorithm => 'bf'

  validates :expire_month, :numericality => { :only_integer => true, :greater_than => 0, :less_than_or_equal_to => 12 }
  validates :expire_year, :numericality => { :only_integer => true, :greater_than => 2000 } 
  
  def accepted_on_billing
    update_attribute :last_successful_bill_date, DateTime.now
  end

  def self.am_card(number, expire_month, expire_year, first_name, last_name)
    ActiveMerchant::Billing::CreditCard.require_verification_value = false
    @cc ||= ActiveMerchant::Billing::CreditCard.new(
      :number     => number,
      :month      => expire_month,
      :year       => expire_year,
      :first_name => first_name,
      :last_name  => last_name
    )
  end
  def am_card
    @cc ||= CreditCard.am_card(number, expire_month, expire_year, member.first_name, member.last_name)
  end

  # refs #17832
  # 6 Days Later if not successful = (+3), 3/2014
  # 6 Days Later if not successful = (+2), 3/2013
  # 6 Days Later if not successful = (+4) 3/2015
  # 6 Days Later if not successful = (+1) 3/2012
  def self.recycle_expired_rule(acc, times)
    if acc.expire_year.to_i < Date.today.year
      case times
        when 1
          new_year_exp=acc.expire_year.to_i + 3
        when 2
          new_year_exp=acc.expire_year.to_i + 2
        when 3
          new_year_exp=acc.expire_year.to_i + 4
        when 4
          new_year_exp=acc.expire_year.to_i + 1
        else
          return acc
      end
      CreditCard.transaction do
        begin
          acc.update_attribute :active , false
          cc = CreditCard.new 
          cc.member = acc.member
          cc.number = acc.number
          cc.expire_month = acc.expire_month
          cc.expire_year = new_year_exp
          cc.active = true
          cc.save!
          return cc
        rescue Exception => e
          logger.error e
          raise ActiveRecord::Rollback
        end
      end
    end
    acc
  end
  
end
