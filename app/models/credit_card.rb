class CreditCard < ActiveRecord::Base
  belongs_to :member
  has_many :transactions

  attr_accessible :active, :number, :expire_month, :expire_year, :blacklisted

  attr_encrypted :number, :key => Settings.cc_encryption_key, :encode => true, :algorithm => 'bf'

  before_create :update_last_digits

  before_destroy :confirm_presence_of_another_credit_card_related_to_member

  validates :expire_month, :numericality => { :only_integer => true, :greater_than => 0, :less_than_or_equal_to => 12 }
  validates :expire_year, :numericality => { :only_integer => true, :greater_than => 2000 }
  validates :number, :numericality => { :only_integer => true }, :allow_blank => true


  def confirm_presence_of_another_credit_card_related_to_member
    if self.active 
      errors[:active] << "Credit card is set as active. It cannot be destroyed."
      return false 
    end

    if member.credit_cards.count == 1
      errors[:credit_card] << "The member should have at least one credit card."
      return false
    end

    if member.is_chargeback?
      errors[:member] << "The member was chargebacked. It cannot be destroyed."
      return false
    end
  end

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
    @am ||= CreditCard.am_card(number, expire_month, expire_year, member.first_name, member.last_name)
  end

  def update_last_digits
    self.last_digits = self.number.last(4) 
  end

  def set_as_active!
    exc = nil
    CreditCard.transaction do 
      begin
        self.member.credit_cards.where([ ' id != ? ', self.id ]).update_all({ active: false })
        self.update_attribute :active , true
        Auditory.audit(nil, self, "Credit card #{last_digits} marked as active.", self.member)
      rescue Exception => e
        exc = e
        Airbrake.notify(:error_class => "CreditCard::set_as_active!", :error_message => "#{e.to_s}\n\n#{$@[0..9] * "\n\t"}", :parameters => { :credit_card => self.inspect, :member => self.member.inspect })
        raise ActiveRecord::Rollback
      end
    end
    raise exc unless exc.nil?
  end
  
  def update_expire(year, month, current_agent = nil)
    if year.to_i == expire_year.to_i and month.to_i == expire_month.to_i
      { :code => Settings.error_codes.success, :message => "New expiration date its identically than the one we have in database." }
    elsif Time.new(year, month) >= Time.zone.now.beginning_of_month
      message = "Changed credit card XXXX-XXXX-XXXX-#{last_digits} from #{expire_month}/#{expire_year} to #{month}/#{year}"
      update_attributes(:expire_month => month, :expire_year => year)
      Auditory.audit(current_agent, self, message, self.member)
      { :code => Settings.error_codes.success, :message => message }
    else
      { :code => Settings.error_codes.invalid_credit_card, :message => Settings.error_messages.invalid_credit_card + " Expiration date could be wrong.", :errors => { :number => "New expiration date is expired." }}
    end
  end

  # refs #17832 and #19603
  # 6 Days Later if not successful = (+3), 3/2014
  # 6 Days Later if not successful = (+2), 3/2013
  # 6 Days Later if not successful = (+4) 3/2015
  # 6 Days Later if not successful = (+1) 3/2012
  def self.recycle_expired_rule(acc, times)
    if acc.am_card.expired?
      case times
      when 0
        new_year_exp=acc.expire_year + 3
      when 1
        new_year_exp=acc.expire_year + 2
      when 2
        new_year_exp=acc.expire_year + 4
      when 3
        new_year_exp=acc.expire_year + 1
      when 4
        new_year_exp=acc.expire_year + 6
      when 5
        new_year_exp=acc.expire_year + 5
      else
        new_year_exp=Time.zone.now.year
      end
      if new_year_exp != acc.expire_year.to_i
        Auditory.audit(nil, acc, "Automatic Recycled Expired card from #{acc.expire_month}/#{acc.expire_year} to #{acc.expire_month}/#{new_year_exp}", acc.member, Settings.operation_types.automatic_recycle_credit_card)
        acc.expire_year = new_year_exp
      end
    end
    acc
  end
end
