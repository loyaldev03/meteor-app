class CreditCard < ActiveRecord::Base
  belongs_to :user
  has_many :transactions

  before_create :set_data_before_credit_card_number_disappear
  before_destroy :confirm_presence_of_another_credit_card_related_to_user
  after_save :elasticsearch_index_asyn_call

  validates :expire_month, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 12 }
  validates :expire_year, numericality: { only_integer: true, greater_than: 2000 }

  BLANK_CREDIT_CARD_TOKEN = 'a'

  def elasticsearch_index_asyn_call
    self.user.async_elasticsearch_index if self.user and not (self.changed & ['last_digits', 'token', 'active']).empty? and self.active
  end

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
  
  def payment_gateway_configuration
    user.club.payment_gateway_configurations.with_deleted.find_by(gateway: gateway)
  end

  def confirm_presence_of_another_credit_card_related_to_user
    if self.active 
      errors[:active] << "Credit card is set as active. It cannot be destroyed."
      return false 
    end

    if user.credit_cards.count == 1
      errors[:credit_card] << "The member should have at least one credit card."
      return false
    end

    if user.is_chargeback?
      errors[:user] << "The member was chargebacked. It cannot be destroyed."
      return false
    end
  end

  def accepted_on_billing
    update_attribute :last_successful_bill_date, Time.zone.now
  end

  # Bug #27501 this method was added just to be used from console.
  def unblacklist
    update_attribute :blacklisted, false
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
    not self.user.lapsed? and not self.blacklisted 
  end

  def can_be_activated?
    not self.active and not self.user.lapsed? and not self.blacklisted and is_same_gateway_as_current_tom? and gateway != 'stripe'
  end

  def is_same_gateway_as_current_tom?
    self.user.club.payment_gateway_configuration.gateway == self.gateway
  end

  def self.am_card(number, expire_month, expire_year, first_name, last_name)
    ActiveMerchant::Billing::CreditCard.require_verification_value = false
    ActiveMerchant::Billing::CreditCard.new(
      number: number,
      month: expire_month,
      year: expire_year,
      first_name: first_name,
      last_name: last_name
    )
  end

  def set_data_before_credit_card_number_disappear
    self.last_digits = self.number.last(4) if self.last_digits.nil? and self.number
  end

  def set_as_active!
    if is_same_gateway_as_current_tom?
      self.user.credit_cards.where([ ' id != ? ', self.id ]).update_all({ active: false })
      self.update_attribute :active , true
      Auditory.audit(nil, self, "Credit card #{last_digits} marked as active.", self.user, Settings.operation_types.credit_card_activated)
    else
      raise CreditCardDifferentGatewaysException.new(message: "Different Gateway")
    end
  end

  def get_token(pgc, puser, allow_cc_blank = false)
    if not self.token
      pgc ||= user.terms_of_membership.payment_gateway_configuration
      am = CreditCard.am_card(number, expire_month, expire_year, puser.first_name || user.first_name, puser.last_name || user.last_name)
      
      if am.valid?
        self.cc_type = am.brand
        begin
          self.token = Transaction.store!(am, pgc, puser||user)
        rescue Exception => e
          if Transaction::STORE_ERROR_NOT_REPORTABLE[pgc.gateway] and not Transaction::STORE_ERROR_NOT_REPORTABLE[pgc.gateway].include? e.to_s
            user = puser || self.user
            Auditory.report_issue("CreditCard:GetToken", e, { credit_card_expire_month: self.expire_month, credit_card_expire_year: self.expire_year, credit_card_type: self.cc_type, club_id: user.club_id, user_name: user.full_name, user: user.email })
          end
          logger.error e.inspect
          self.errors[:number] << I18n.t('error_messages.get_token_mes_error')
        end
      elsif allow_cc_blank
        self.cc_type = 'unknown'
        self.token = BLANK_CREDIT_CARD_TOKEN # fixing this token for blank credit cards
      else
        # uncomment this line ONLY If #55804192 is approved
        # self.errors[:number] << "is not a valid credit card number" if am.errors["number"].empty? and not am.errors["brand"].empty?
        self.errors[:number] << am.errors["number"].join(", ") unless am.errors["number"].empty?
        self.errors[:expire_month] << am.errors["month"].join(", ") unless am.errors["month"].empty?
        self.errors[:expire_year] << am.errors["year"].join(", ") unless am.errors["year"].empty?
        self.token = BLANK_CREDIT_CARD_TOKEN # fixing this token for blank credit cards. #54934966
      end
    end
    self.gateway = pgc.gateway
    self.token
  end

  # refs #17832 and #19603
  # 6 Days Later if not successful = (+3), 3/2014
  # 6 Days Later if not successful = (+2), 3/2013
  # 6 Days Later if not successful = (+4) 3/2015
  # 6 Days Later if not successful = (+1) 3/2012
  def recycle_expired_rule(times)
    if expired? or (user.recycled_times > 0 and user.has_been_sd_cc_expired?)
      case times
      when 0
        new_year_exp=self.expire_year + 3
      when 1
        new_year_exp=self.expire_year + 2
      when 2
        new_year_exp=self.expire_year + 4
      when 3
        new_year_exp=self.expire_year + 1
      when 4
        new_year_exp=self.expire_year + 6
      when 5
        new_year_exp=self.expire_year + 5
      else
        new_year_exp=Time.zone.now.year
      end
      if new_year_exp != self.expire_year.to_i
        Auditory.audit(nil, self, "Automatic Recycled Expired card from #{expire_month}/#{expire_year} to #{expire_month}/#{new_year_exp}", user, Settings.operation_types.automatic_recycle_credit_card)
        self.expire_year = new_year_exp
      end
    end
  end 

  def update_expire(year, month, current_agent = nil)
    if year.to_i == expire_year.to_i and month.to_i == expire_month.to_i
      { code: Settings.error_codes.success, message: "New expiration date its identically than the one we have in database." }
    elsif Time.new(year, month, nil, nil, nil, nil, self.user.get_offset_related) >= Time.now.in_time_zone(self.user.get_club_timezone).beginning_of_month
      message = "Changed credit card XXXX-XXXX-XXXX-#{last_digits} from #{expire_month}/#{expire_year} to #{month}/#{year}"
      update_attributes(expire_month: month, expire_year: year)
      Auditory.audit(current_agent, self, message, self.user, Settings.operation_types.credit_card_updated)
      { code: Settings.error_codes.success, message: message }
    else
      { code: Settings.error_codes.invalid_credit_card, message: I18n.t('error_messages.invalid_credit_card') + " Expiration date could be wrong.", errors: { number: "New expiration date is expired." }}
    end
  end

  def expired?
    Time.utc(expire_year, expire_month) < Time.now.utc.beginning_of_month
  end
end
