class CreditCard < ActiveRecord::Base
  belongs_to :member
  has_many :transactions

  attr_accessible :active, :number, :expire_month, :expire_year, :blacklisted

  before_create :set_data_before_credit_card_number_disappear
  before_destroy :confirm_presence_of_another_credit_card_related_to_member

  validates :expire_month, :numericality => { :only_integer => true, :greater_than => 0, :less_than_or_equal_to => 12 }
  validates :expire_year, :numericality => { :only_integer => true, :greater_than => 2000 }

  def number=(x)
    @number = if x.include?('XXXX')
      x.to_s
    else
      x.to_s.gsub(/\D/,'') 
    end
  end

  def number
    @number
  end

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

  def set_data_before_credit_card_number_disappear
    self.last_digits = self.number.last(4) if self.last_digits.nil? and self.number
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

  def get_token(pgc = nil, first_name = nil, last_name = nil, allow_cc_blank = false)
    am = CreditCard.am_card(number, expire_month, expire_year, first_name || member.first_name, last_name || member.last_name)
    if am.valid?
      self.cc_type = am.type
      begin
        self.token = Transaction.store!(am, pgc || member.terms_of_membership.payment_gateway_configuration)
      rescue
        self.errors[:number] << I18n.t('error_messages.get_token_mes_error')
      end
    elsif allow_cc_blank
      self.cc_type = 'unknown'
      self.token = "a" # fixing this token for blank credit cards
    else
      self.errors[:number] << am.errors["number"].join(", ") unless am.errors["number"].empty?
      self.errors[:expire_month] << am.errors["month"].join(", ") unless am.errors["month"].empty?
      self.errors[:expire_year] << am.errors["year"].join(", ") unless am.errors["year"].empty?
    end
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
      { :code => Settings.error_codes.invalid_credit_card, :message => I18n.t('error_messages.invalid_credit_card') + " Expiration date could be wrong.", :errors => { :number => "New expiration date is expired." }}
    end
  end

  def expired?
    Time.utc(expire_year, expire_month) < Time.now.utc.beginning_of_month
  end

end
