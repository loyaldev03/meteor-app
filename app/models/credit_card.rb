class CreditCard < ActiveRecord::Base
  belongs_to :member
  has_many :transactions

  attr_accessible :active, :number, :expire_month, :expire_year, :blacklisted

  attr_encrypted :number, :key => Settings.cc_encryption_key, :encode => true, :algorithm => 'bf'

  before_create :update_last_digits

  validates :expire_month, :numericality => { :only_integer => true, :greater_than => 0, :less_than_or_equal_to => 12 }, :allow_blank => true
  validates :expire_year, :numericality => { :only_integer => true, :greater_than => 2000 }, :allow_blank => true
  validates :number, :numericality => { :only_integer => true }, :allow_blank => true
  #method commented. It doesnt allow to blacklist an active credit card.  
  #before_update :not_blacklisted

  def accepted_on_billing
    update_attribute :last_successful_bill_date, Time.zone.now
  end

  def blacklist
    update_attribute :blacklisted, true
  end

  def activate
    update_attribute :active, true unless blacklisted
  end

  def deactivate
    update_attribute :active, false
  end

  def blacklist_active_credit_card
    update_attribute :blacklisted, true
  end
  
  def error_to_s(delimiter = "\n")
    self.errors.collect {|attr, message| "#{attr}: #{message}" }.join(delimiter)
  end

  def can_be_blacklisted?
    not self.member.lapsed? and not self.blacklisted 
  end

  def can_be_activated?
    not self.active and not self.member.lapsed? and not self.blacklisted
  end

  def self.am_card(number, expire_month, expire_year, first_name, last_name)
    ActiveMerchant::Billing::CreditCard.require_verification_value = false
    ActiveMerchant::Billing::CreditCard.new(
      :number     => number,
      :month      => expire_month,
      :year       => expire_year,
      :first_name => first_name,
      :last_name  => last_name
    )
  end

  def am_card
    CreditCard.am_card(number, expire_month, expire_year, member.first_name, member.last_name)
  end

  def update_last_digits
    self.last_digits = self.number.last(4) unless self.last_digits.nil?
  end
  
  # refs #17832 and #19603
  # 6 Days Later if not successful = (+3), 3/2014
  # 6 Days Later if not successful = (+2), 3/2013
  # 6 Days Later if not successful = (+4) 3/2015
  # 6 Days Later if not successful = (+1) 3/2012
  def self.recycle_expired_rule(acc, times)
    if acc.am_card.expired?
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
          Auditory.audit(nil, cc, "Automatic Recycled Expired card", cc.member, Settings.operation_types.automatic_recycle_credit_card)
          return cc
        rescue Exception => e
          logger.error e
          raise ActiveRecord::Rollback
        end
      end
    end
    acc
  end
  # Custom method to verify if its blacklisted - not using it because it doenst allow to blacklist an active creditcard.
  # def not_blacklisted
  #   if self.blacklisted? && self.active?
  #     errors.add(:active, "Cannot be activated. Its blacklisted") 
  #     false
  #   end
  # end

end
