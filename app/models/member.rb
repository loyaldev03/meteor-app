# encoding: utf-8
class Member < ActiveRecord::Base
  extend Extensions::Member::CountrySpecificValidations

  belongs_to :club
  belongs_to :member_group_type
  has_many :member_notes
  has_many :credit_cards
  has_many :transactions, :order => "created_at ASC"
  has_many :operations
  has_many :communications, :order => "created_at DESC"
  has_many :fulfillments
  has_many :club_cash_transactions
  has_many :enrollment_infos, :order => "created_at DESC"
  has_many :member_preferences
  has_many :memberships, :order => "created_at DESC"
  belongs_to :current_membership, :class_name => 'Membership'

  # TODO: should we use delegate??
  delegate :terms_of_membership, :to => :current_membership
  # attr :terms_of_membership_id # is it necesarilly??? 
  delegate :terms_of_membership_id, :to => :current_membership
  delegate :join_date, :to => :current_membership
  delegate :cancel_date, :to => :current_membership
  delegate :quota, :to => :current_membership
  delegate :time_zone, :to => :club
  ##### 

  attr_accessible :address, :bill_date, :city, :country, :description, 
      :email, :external_id, :first_name, :phone_country_code, :phone_area_code, :phone_local_number, 
      :last_name, :next_retry_bill_date, 
      :bill_date, :state, :zip, :member_group_type_id, :blacklisted, :wrong_address,
      :wrong_phone_number, :credit_cards_attributes, :birth_date,
      :gender, :type_of_phone_number, :preferences

  serialize :preferences, JSON

  before_create :record_date
  before_save :wrong_address_logic

  after_update 'after_save_sync_to_remote_domain(:update)'
  after_destroy :cancel_member_at_remote_domain
  after_create 'asyn_desnormalize_preferences(force: true)'
  after_update :asyn_desnormalize_preferences

  # skip_api_sync wont be use to prevent remote destroy. will be used to prevent creates/updates
  def cancel_member_at_remote_domain
    api_member.destroy! unless api_member.nil? || api_id.nil?
  rescue Exception => e
    # refs #21133
    # If there is connectivity problems or data errors with drupal. Do not stop enrollment!! 
    # Because maybe we have already bill this member.
    Airbrake.notify(:error_class => "Member:account_cancel:sync", :error_message => e, :parameters => { :member => self.inspect })
  end

  def after_save_sync_to_remote_domain(type)
    unless @skip_api_sync || api_member.nil?
      time_elapsed = Benchmark.ms do
        api_member.save!
      end
      logger.info "Drupal::sync took #{time_elapsed}ms"
    end
  rescue Exception => e
    # refs #21133
    # If there is connectivity problems or data errors with drupal. Do not stop enrollment!! 
    # Because maybe we have already bill this member.
    Airbrake.notify(:error_class => "Member:#{type.to_s}:sync", :error_message => e, :parameters => { :member => self.inspect })
  end

  validates :country, 
    presence:                    true, 
    length:                      { is: 2, allow_nil: true },
    inclusion:                   { within: self.supported_countries }
  country_specific_validations!

  scope :synced, lambda { |bool=true|
    bool ?
      where('sync_status = "synced"') :
      where('sync_status = "not_synced"')
  }
  scope :with_sync_status, lambda { |status=true|
    case status
    when nil, ''
      where('')
    when true, 'true', 'synced'
      synced
    when false, 'false', 'unsynced'
      synced(false)
    when 'error'
      where('sync_status = "with_error"')
    when 'noerror'
      where('sync_status IN ("not_synced", "synced")')
    end
  }
  scope :billable, lambda { where('status IN (?, ?)', 'provisional', 'active') }
  scope :with_id, lambda { |value| where('members.id = ?', value.strip) unless value.blank? }
  scope :with_next_retry_bill_date, lambda { |value| where('next_retry_bill_date BETWEEN ? AND ?', value.to_date.to_time_in_current_zone.beginning_of_day, value.to_date.to_time_in_current_zone.end_of_day) unless value.blank? }
  scope :with_phone_country_code, lambda { |value| where('phone_country_code = ?', value.strip) unless value.blank? }
  scope :with_phone_area_code, lambda { |value| where('phone_area_code = ?', value.strip) unless value.blank? }
  scope :with_phone_local_number, lambda { |value| where('phone_local_number = ?', value.strip) unless value.blank? }
  scope :with_first_name_like, lambda { |value| where('first_name like ?', '%'+value.strip+'%') unless value.blank? }
  scope :with_last_name_like, lambda { |value| where('last_name like ?', '%'+value.strip+'%') unless value.blank? }
  scope :with_address_like, lambda { |value| where('address like ?', '%'+value.strip+'%') unless value.blank? }
  scope :with_city_like, lambda { |value| where('city like ?', '%'+value.strip+'%') unless value.blank? }
  scope :with_country_like, lambda { |value| where('country like ?', value) unless value.blank? }
  scope :with_state_like, lambda { |value| where('state like ?', value) unless value.blank? }
  scope :with_zip, lambda { |value| where('zip like ?', '%'+value.strip+'%') unless value.blank? }
  scope :with_email_like, lambda { |value| where('email like ?', '%'+value.strip+'%') unless value.blank? }
  scope :with_credit_card_last_digits, lambda{ |value| joins(:credit_cards).where('last_digits = ?', value.strip) unless value.blank? }
  scope :with_member_notes, lambda{ |value| joins(:member_notes).where('description like ?', '%'+value.strip+'%') unless value.blank? }
  scope :with_external_id, lambda{ |value| where("external_id = ?",value) unless value.blank? }
  scope :needs_approval, lambda{ |value| where('members.status = ?', 'applied') unless value == '0' }

  state_machine :status, :initial => :none, :action => :save_state do
    ###### member gets applied =====>>>>
    after_transition :lapsed => 
                        :applied, :do => [:set_join_date, :send_recover_needs_approval_email]
    after_transition [ :none, :provisional, :active ] => # none is new join. provisional and active are save the sale
                        :applied, :do => [:set_join_date, :send_active_needs_approval_email]
    ###### <<<<<<========
    ###### member gets active =====>>>>
    after_transition :provisional => 
                        :active, :do => :send_active_email
    ###### <<<<<<========
    ###### member gets provisional =====>>>>
    after_transition [ :none, :lapsed ] => # enroll and reactivation
                        :provisional, :do => 'schedule_first_membership(true)'
    after_transition [ :provisional, :active ] => 
                        :provisional, :do => 'schedule_first_membership(true, true, true, true)' # save the sale
    after_transition :applied => 
                        :provisional, :do => 'schedule_first_membership(false)'
    ###### <<<<<<========
    ###### Reactivation handling =====>>>>
    after_transition :lapsed => 
                        [:applied, :provisional], :do => :increment_reactivations
    ###### <<<<<<========
    ###### Cancellation =====>>>>
    after_transition [:provisional, :active ] => 
                        :lapsed, :do => [:cancellation, :nillify_club_cash]
    after_transition :applied => 
                        :lapsed, :do => :set_member_as_rejected
    ###### <<<<<<========
    after_transition all => all, :do => :propagate_membership_data

    event :set_as_provisional do
      transition [:none, :provisional,:applied, :active] => :provisional
    end
    event :set_as_active do
      transition [:provisional, :active] => :active
    end
    event :set_as_canceled do
      transition [:provisional, :active, :applied] => :lapsed
    end
    event :recovered do 
      transition [:lapsed] => :provisional
    end
    event :set_as_applied do 
      transition [:lapsed, :none, :active, :provisional] => :applied
    end

    # A Member is within their review period. These members have joined a Subscription program that has a “Provisional” 
    # period whereby the Member has an opportunity to review the benfits of the program risk free for the duration of 
    # the Provisional period. 
    state :provisional
    # A Member who has joineda subscription program that has been successfully billed the the 
    # Membership Billing Amount and is still active in the Program. 
    state :active
    # Where a Member in Provisional or active Status Cancels their Subscription or their Subscription 
    # was canceled by the platform due to unsuccessful billing of the Membership Amount or Renewal Amount.
    state :lapsed
    # (ONLY IN NFLA PLAYER PROGRAM) When a member has been submitted information as a Prospect 
    # COF and is in provisional status who needs to be approved to join the NFLA, (Approvals are 
    # done through NFLA and managed by Stoneacre)
    state :applied
  end

  def save_state
    save(:validate => false)
  end

  # Sends the activation mail.
  def send_active_email
    Communication.deliver!(:active, self)
  end

  # Sends the request mail to every representative to accept/reject the member.
  def send_active_needs_approval_email
    representatives = ClubRole.find_all_by_club_id_and_role(self.club_id,'representative')
    representatives.each { |representative| Notifier.active_with_approval(representative.agent,self).deliver! }
  end

  # Sends the request mail to every representative to accept/reject the member.
  def send_recover_needs_approval_email
    representatives = ClubRole.find_all_by_club_id_and_role(self.club_id,'representative')
    representatives.each { |representative| Notifier.recover_with_approval(representative.agent,self).deliver! }
  end

  # Increment reactivation times upon recovering a member. (From lapsed to provisional or applied)
  def increment_reactivations
    increment!(:reactivation_times, 1)
  end

  # Sets join date. It is called multiple times.
  def set_join_date
    membership = current_membership
    membership.join_date = Time.zone.now
    membership.save
  end

  def set_member_as_rejected
    decrement!(:reactivation_times, 1) if reactivation_times > 0 # we increment when it gets applied. If we reject the member we have to get back
    self.current_membership.update_attribute(:cancel_date, Time.zone.now)
  end

  # Sends the fulfillment, and it settes bill_date and next_retry_bill_date according to member's terms of membership.
  def schedule_first_membership(set_join_date, skip_send_fulfillment = false, nbd_update_for_sts = false, skip_add_club_cash = false)
    send_fulfillment unless skip_send_fulfillment
    add_club_cash(nil,terms_of_membership.club_cash_amount, 'club cash on enroll') unless skip_add_club_cash

    membership = current_membership
    if set_join_date
      membership.update_attribute :join_date, Time.zone.now
    end
    if nbd_update_for_sts
      if terms_of_membership.monthly? # we need this if to avoid Bug #27211
        self.bill_date = self.next_retry_bill_date
      end
    else
      if terms_of_membership.monthly?
        self.bill_date = membership.join_date + terms_of_membership.provisional_days.days
        self.next_retry_bill_date = self.bill_date
      else
        self.bill_date = membership.join_date
        self.next_retry_bill_date = membership.join_date + terms_of_membership.provisional_days.days
      end
    end
    self.save(:validate => false)
  end

  # Changes next bill date.
  def change_next_bill_date(next_bill_date, current_agent = nil)
    if not self.can_change_next_bill_date?
      errors = { :member => 'is not in billable status' }
      answer = { :message => I18n.t('error_messages.unable_to_perform_due_member_status'), :code => Settings.error_codes.next_bill_date_blank, :errors => errors }
    elsif next_bill_date.blank?
      errors = { :next_bill_date => 'is blank' }
      answer = { :message => I18n.t('error_messages.next_bill_date_blank'), :code => Settings.error_codes.next_bill_date_blank, :errors => errors }
    elsif next_bill_date.to_datetime < Time.zone.now.to_date
      errors = { :next_bill_date => 'Is prior to actual date' }
      answer   = { :message => "Next bill date should be older that actual date.", :code => Settings.error_codes.next_bill_date_prior_actual_date, :errors => errors }
    elsif self.valid? and not self.active_credit_card.expired?  
      self.next_retry_bill_date = next_bill_date.to_datetime
      self.bill_date = next_bill_date.to_datetime
      self.save(:validate => false)
      message = "Next bill date changed to #{next_bill_date}"
      Auditory.audit(current_agent, self, message, self, Settings.operation_types.change_next_bill_date)
      answer = {:message => message, :code => Settings.error_codes.success }
    else
      errors = self.errors.to_hash
      errors = errors.merge!({:credit_card => "is expired"}) if self.active_credit_card.expired?
      answer = { :errors => errors, :code => Settings.error_codes.member_data_invalid }
    end
    answer
  rescue ArgumentError => e
    return { :message => "Next bill date wrong format.", :errors => { :next_bill_date => "invalid date"}, :code => Settings.error_codes.wrong_data } 
  rescue Exception => e
    Airbrake.notify(:error_class => "Member:change_next_bill_date", :error_message => e, :parameters => { :member => self.inspect })
    return { :message => I18n.t('error_messages.airbrake_error_message'), :code => Settings.error_codes.could_not_change_next_bill_date }
  end

  # Returns a string with first and last name concatenated. 
  def full_name
    [ first_name, last_name].join(' ').squeeze(' ')
  end

  def country_name
    self.class.country_name(self.country.downcase)
  end

  # Returns the active credit card that the member is using at the moment.
  def active_credit_card
    self.credit_cards.find_by_active(true)
  end

  # Returns a string with address, city and state concatenated. 
  def full_address
    [address, city, state].join(' ')
  end

  def full_phone_number
    "(#{self.phone_country_code}) #{self.phone_area_code} - #{self.phone_local_number}"
  end

  ####  METHODS USED TO SHOW OR NOT BUTTONS. 

  def can_be_synced_to_remote?
    !(lapsed? or applied?)
  end

  # Returns true if members is lapsed.
  def can_be_canceled?
    !self.lapsed? 
  end

  # Returns true if member is applied. 
  def can_be_approved?
    self.applied?
  end

  # Returns true if member is applied.
  def can_be_rejected?
    self.applied?
  end

  # Returns true if member is active or provisional.
  def can_save_the_sale?
    self.active? or self.provisional?
  end

  def status_enable_to_bill?
    self.active? or self.provisional?
  end

  # Returns true if member is active or provisional.
  def can_bill_membership?
    status_enable_to_bill? and self.club.billing_enable
  end

  # Returns true if member is lapsed or if it didnt reach the max reactivation times.
  def can_recover?
    # TODO: Add logic to recover some one max 3 times in 5 years
    self.lapsed? and reactivation_times < Settings.max_reactivations and not self.blacklisted
  end

  def is_chargeback?
    self.operations.each do |operation|
      return true if operation.operation_type == 110
    end
    false
  end

  # refs #21919
  def can_renew_fulfillment?
    self.active? and 
    (self.recycled_times == 0 and 
      (
        (terms_of_membership.monthly? and (self.current_membership.quota % 12)==0) or
        # self.current_membership.quota > 12 .. yes we need it . because quota = 12 and 2012-2012=0 +1*12 => 12
        (terms_of_membership.yearly? and self.current_membership.quota > 12 and (self.current_membership.quota == (12 * (Time.zone.now.year - self.current_membership.join_date.year + 1))))
      )
    )
  end

  # Returns true if member is not blacklisted and not lapsed
  def can_be_blacklisted?
    !self.blacklisted?
  end

  def can_add_club_cash?
    if club_cash_transactions_enabled
      return true
    elsif not (self.api_id.blank? or self.api_id.nil?)
      return true
    end
    false
  end

  def can_change_next_bill_date?
    not self.next_retry_bill_date.nil? and not self.lapsed?
  end

  ###############################################

  def save_the_sale(new_tom_id, agent = nil)
    if can_save_the_sale?
      if new_tom_id.to_i == terms_of_membership.id
        { :message => "Nothing to change. Member is already enrolled on that TOM.", :code => Settings.error_codes.nothing_to_change_tom }
      else
        old_tom_id = terms_of_membership.id
        prev_membership_id = current_membership.id
        res = enroll(TermsOfMembership.find(new_tom_id), self.active_credit_card, 0.0, agent, false, 0, self.current_membership.enrollment_info, true, true)
        if res[:code] == Settings.error_codes.success
          Auditory.audit(agent, TermsOfMembership.find(new_tom_id), 
            "Save the sale from TOM(#{old_tom_id}) to TOM(#{new_tom_id})", self, Settings.operation_types.save_the_sale)
        end
        # update manually this fields because we cant cancel member
        Membership.find(prev_membership_id).cancel_because_of_save_the_sale
        res
      end
    else
      { :message => "Member status does not allows us to save the sale.", :code => Settings.error_codes.member_status_dont_allow }
    end
  end

  # Recovers the member. Changes status from lapsed to applied or provisional (according to members term of membership.)
  def recover(new_tom, agent = nil)
    enroll(new_tom, self.active_credit_card, 0.0, agent, true, 0, self.current_membership.enrollment_info, true, false)
  end

  def bill_membership
    if can_bill_membership? and self.next_retry_bill_date <= Time.zone.now
      amount = terms_of_membership.installment_amount
      if terms_of_membership.payment_gateway_configuration.nil?
        message = "TOM ##{terms_of_membership.id} does not have a gateway configured."
        Auditory.audit(nil, terms_of_membership, message, self, Settings.operation_types.membership_billing_without_pgc)
        Airbrake.notify(:error_class => "Billing", :error_message => message, :parameters => { :member => self.inspect, :membership => current_membership.inspect })
        { :code => Settings.error_codes.tom_wihtout_gateway_configured, :message => message }
      else
        trans = Transaction.obtain_transaction_by_gateway(terms_of_membership.payment_gateway_configuration.gateway)
        trans.transaction_type = "sale"
        trans.prepare(self, active_credit_card, amount, terms_of_membership.payment_gateway_configuration)
        answer = trans.process
        if trans.success?
          unless set_as_active
            Airbrake.notify(:error_class => "Billing::set_as_active", :error_message => "we cant set as active this member.", :parameters => { :member => self.inspect, :membership => current_membership.inspect, :trans => trans.inspect })
          end
          schedule_renewal
          assign_club_cash
          message = "Member billed successfully $#{amount} Transaction id: #{trans.id}"
          Auditory.audit(nil, trans, message, self, Settings.operation_types.membership_billing)
          { :message => message, :code => Settings.error_codes.success, :member_id => self.id }
        else
          message = set_decline_strategy(trans)
          answer # TODO: should we answer set_decline_strategy message too?
        end
      end
    else
      if not self.club.billing_enable
        { :message => "Member's club is not allowing billing", :code => Settings.error_codes.member_club_dont_allow }
      elsif not status_enable_to_bill?
        { :message => "Member is not in a billing status.", :code => Settings.error_codes.member_status_dont_allow }
      else
        { :message => "We haven't reach next bill date yet.", :code => Settings.error_codes.billing_date_not_reached }
      end
    end
  end

  def bill_event(amount, description)
    if amount.blank? or description.blank?
      answer = { :message =>"Amount and description cannot be blank.", :code => Settings.error_codes.wrong_data }
    else
      if can_bill_membership?
        trans = Transaction.obtain_transaction_by_gateway(terms_of_membership.payment_gateway_configuration.gateway)
        trans.transaction_type = "event_billing"
        trans.prepare(self, active_credit_card, amount, terms_of_membership.payment_gateway_configuration)
        answer = trans.process
        if trans.success?
          message = "Member billed successfully $#{amount} Transaction id: #{trans.id}. Reason: #{description}"
          transaction = Transaction.find(trans.id)
          transaction.update_attribute :response_result, transaction.response_result+". Reason: #{description}"
          answer = { :message => message, :code => Settings.error_codes.success }
        else
          answer = { :message => trans.response_result, :code => Settings.error_codes.could_not_event_bill }
        end
      else
        if not self.club.billing_enable
          answer = { :message => "Member's club is not allowing billing", :code => Settings.error_codes.member_club_dont_allow }
        else
          answer = { :message => "Member is not in a billing status.", :code => Settings.error_codes.member_status_dont_allow }
        end
      end
    end
    Auditory.audit(nil, trans, answer[:message], self, Settings.operation_types.event_billing)
    answer
  rescue Exception => e
    Airbrake.notify(:error_class => "Billing:event_billing", :error_message => e, :parameters => { :member => self.inspect })
    { :message => I18n.t('error_messages.airbrake_error_message'), :code => Settings.error_codes.could_not_event_bill }
  end

  def error_to_s(delimiter = "\n")
    self.errors.collect {|attr, message| "#{attr}: #{message}" }.join(delimiter)
  end

  def errors_merged(credit_card)
    errors = self.errors.to_hash
    errors.merge!(credit_card: credit_card.errors.to_hash) unless credit_card.errors.empty?
    errors
  end

  def self.enroll(tom, current_agent, enrollment_amount, member_params, credit_card_params, cc_blank = false, skip_api_sync = false)
    credit_card_params = {} if credit_card_params.blank? # might be [], we expect a Hash
    club = tom.club

    unless club.billing_enable
      return { :message => I18n.t('error_messages.club_is_not_enable_for_new_enrollments', :cs_phone_number => club.cs_phone_number), :code => Settings.error_codes.club_is_not_enable_for_new_enrollments }      
    end
    
    # credit card exist? . we need this token for CreditCard.joins(:member) and enrollment billing.
    credit_card = CreditCard.new credit_card_params
    credit_card.get_token(tom.payment_gateway_configuration, member_params[:first_name], member_params[:last_name], cc_blank)

    member = Member.find_by_email_and_club_id(member_params[:email], club.id)
    if member.nil?
      member = Member.new
      member.update_member_data_by_params member_params
      member.skip_api_sync! if member.api_id.present? || skip_api_sync
      member.club = club
      unless member.valid? and credit_card.errors.size == 0
        return { :message => I18n.t('error_messages.member_data_invalid'), :code => Settings.error_codes.member_data_invalid, 
                 :errors => member.errors_merged(credit_card) }
      end
    elsif member.blacklisted
      message = I18n.t('error_messages.member_email_blacklisted', :cs_phone_number => club.cs_phone_number)
      Auditory.audit(current_agent, tom, message, member, Settings.operation_types.member_email_blacklisted)
      return { :message => message, :code => Settings.error_codes.member_email_blacklisted, :errors => {:blacklisted => "Member is blacklisted"} }
    else
      member.skip_api_sync! if member.api_id.present? || skip_api_sync
      member.update_member_data_by_params member_params
      # first update first name and last name, then validate credti card
    end

    answer = member.validate_if_credit_card_already_exist(tom, credit_card_params[:number], credit_card_params[:expire_year], credit_card_params[:expire_month], true, cc_blank, current_agent)
    unless answer[:code] == Settings.error_codes.success
      return answer
    end

    member.enroll(tom, credit_card, enrollment_amount, current_agent, true, cc_blank, member_params, false, false)
  end

  def enroll(tom, credit_card, amount, agent = nil, recovery_check = true, cc_blank = false, member_params = nil, skip_credit_card_validation = false, skip_product_validation = false)
    allow_cc_blank = (amount.to_f == 0.0 and cc_blank)
    club = tom.club

    unless skip_product_validation
      member_params[:product_sku].split(',').each do |sku|
        product = Product.find_by_club_id_and_sku(club.id,sku)
        if product.nil?
          return { :message => I18n.t('error_messages.product_does_not_exists'), :code => Settings.error_codes.product_does_not_exists }
        else
          if not product.has_stock?
            return { :message => I18n.t('error_messages.product_out_of_stock'), :code => Settings.error_codes.product_out_of_stock }
          end
        end
      end
    end

    if not self.new_record? and recovery_check and not self.lapsed? 
      return { :message => I18n.t('error_messages.member_already_active', :cs_phone_number => club.cs_phone_number), :code => Settings.error_codes.member_already_active, :errors => { :status => "Already active." } }
    elsif recovery_check and not self.new_record? and not self.can_recover?
      return { :message => I18n.t('error_messages.cant_recover_member', :cs_phone_number => club.cs_phone_number), :code => Settings.error_codes.cant_recover_member, :errors => {:reactivation_times => "Max reactivation times reached."} }
    end

    # CLEAN ME: => This validation is done at self.enroll
    unless self.valid? 
      return { :message => I18n.t('error_messages.member_data_invalid'), :code => Settings.error_codes.member_data_invalid, 
               :errors => self.errors_merged(credit_card) }
    end

    enrollment_info = EnrollmentInfo.new :enrollment_amount => amount, :terms_of_membership_id => tom.id
    enrollment_info.update_enrollment_info_by_hash member_params
    membership = Membership.new(terms_of_membership_id: tom.id, created_by: agent)
    self.current_membership = membership

    if amount.to_f != 0.0
      trans = Transaction.obtain_transaction_by_gateway(tom.payment_gateway_configuration.gateway)
      trans.transaction_type = "sale"
      trans.prepare(self, credit_card, amount, tom.payment_gateway_configuration)
      answer = trans.process
      unless trans.success?
        Auditory.audit(agent, trans, "Transaction was not successful.", (self.new_record? ? nil : self), Settings.operation_types.error_on_enrollment_billing)
        return answer 
      end
    end
    
    begin
      if self.new_record?
        self.credit_cards << credit_card
      elsif not skip_credit_card_validation
        validate_if_credit_card_already_exist(tom, credit_card.number, credit_card.expire_year, credit_card.expire_month, false, cc_blank, agent)
        credit_card = active_credit_card
      end
      self.enrollment_infos << enrollment_info
      self.memberships << membership
      self.save!

      enrollment_info.membership = membership
      enrollment_info.save
      
      if trans
        # We cant assign this information before , because models must be created AFTER transaction
        # is completed succesfully
        trans.member_id = self.id
        trans.credit_card_id = credit_card.id
        trans.save
        credit_card.accepted_on_billing
      end
      self.reload
      message = set_status_on_enrollment!(agent, trans, amount, enrollment_info)

      { :message => message, :code => Settings.error_codes.success, :member_id => self.id, :autologin_url => self.full_autologin_url.to_s }
    rescue Exception => e
      logger.error e.inspect
      error_message = (self.id.nil? ? "Member:enroll" : "Member:recovery/save the sale") + " -- member turned invalid while enrolling"
      Airbrake.notify(:error_class => error_message, :error_message => e, :parameters => { :member => self.inspect, :credit_card => credit_card.inspect, :enrollment_info => enrollment_info.inspect })
      # TODO: this can happend if in the same time a new member is enrolled that makes this an invalid one. Do we have to revert transaction?
      Auditory.audit(agent, self, error_message, self, Settings.operation_types.error_on_enrollment_billing)
      { :message => I18n.t('error_messages.member_not_saved', :cs_phone_number => self.club.cs_phone_number), :code => Settings.error_codes.member_not_saved }
    end
  end

  def send_pre_bill
    Communication.deliver!(:prebill, self) if can_bill_membership?
  end

  def send_fulfillment
    # we always send fulfillment to new members or members that do not have 
    # opened fulfillments (meaning that previous fulfillments expired).
    if self.fulfillments.where_not_processed.empty?
      fulfillments = fulfillments_products_to_send
      fulfillments.each do |sku|
        product = Product.find_by_sku_and_club_id(sku, self.club_id)
        f = Fulfillment.new :product_sku => sku
        unless product.nil?
          f.product_package = product.package
          f.recurrent = product.recurrent 
        end
        f.member_id = self.id
        f.save
        answer = f.decrease_stock!
        unless answer[:code] == Settings.error_codes.success
          Airbrake.notify(:error_class => answer[:message], :error_message => answer[:message], :parameters => { :member => self.inspect, :credit_card => self.active_credit_card, :enrollment_info => self.current_membership.enrollment_info })
        end
      end
    end
  end

  def sync?
    self.club.sync?
  end

  def api_member
    @api_member ||= if !self.sync?
      nil
    else
      club.api_type.constantize.new self
    end
  end

  def skip_api_sync!
    @skip_api_sync = true
  end

  def pardot_sync?
    self.club.pardot_sync?
  end

  def pardot_member
    @pardot_member ||= if !self.pardot_sync?
      nil
    else
      Pardot::Member.new self
    end
  end

  def skip_pardot_sync!
    @skip_pardot_sync = true
  end

  def synced?
    sync_status=="synced"
  end

  def synced_with_error?
    sync_status=="with_error"
  end

  def get_sync_status
    if synced_with_error?
      'error'
    else
      if self.synced?
        'synced'
      else
        'unsynced'
      end
    end
  end

  def refresh_autologin_url!
    self.api_member && self.api_member.login_token rescue nil
  end

  def full_autologin_url
    c = self.club
    d = c.api_domain if c

    if d and self.autologin_url
      URI.parse(d.url) + self.autologin_url
    else
      nil
    end
  end

  ##################### Club cash ####################################

  delegate :club_cash_transactions_enabled, :to => :club

  # Resets member club cash in case of a cancelation.
  def nillify_club_cash
    if club.allow_club_cash_transaction?
      add_club_cash(nil, -club_cash_amount, 'Removing club cash because of member cancellation')
      if club_cash_transactions_enabled
        self.club_cash_expire_date = nil
        self.save(:validate => false)
      end
    end
  end

  # Resets member club cash in case the club cash has expired.
  def reset_club_cash
    add_club_cash(nil, -club_cash_amount, 'Removing expired club cash.')
    if club_cash_transactions_enabled
      self.club_cash_expire_date = self.club_cash_expire_date + 12.months
      self.save(:validate => false)
    end
  end

  # Adds club cash when membership billing is success. Only on each 12th month, and if it is not the first billing.
  def assign_club_cash(message = "Adding club cash after billing")
    if current_membership.quota%12==0 and current_membership.quota!=12
      amount = (self.member_group_type_id ? Settings.club_cash_for_members_who_belongs_to_group : terms_of_membership.club_cash_amount)
      self.add_club_cash(nil, amount, message)
      if club_cash_transactions_enabled
        if self.club_cash_expire_date.nil? # first club cash assignment
          self.club_cash_expire_date = join_date + 1.year
        end
        self.save(:validate => false)
      end
    end
  rescue Exception => e
    # refs #21133
    # If there is connectivity problems or data errors with drupal. Do not stop billing!! 
    Airbrake.notify(:error_class => "Member:assign_club_cash:sync", :error_message => e, :parameters => { :member => self.inspect, :amount => amount, :message => message })
  end
  
  # Adds club cash transaction. 
  def add_club_cash(agent, amount = 0,description = nil)
    answer = { :code => Settings.error_codes.club_cash_transaction_not_successful, :message => "Could not save club cash transaction"  }
    ClubCashTransaction.transaction do
      begin
        if not club.allow_club_cash_transaction?
          answer = { :message =>I18n.t("error_messages.club_cash_not_supported"), :code => Settings.error_codes.club_does_not_support_club_cash }
        elsif amount.to_f == 0
          answer[:message] = I18n.t("error_messages.club_cash_transaction_invalid_amount")
          answer[:errors] = { :amount => "Invalid amount" } 
        elsif club_cash_transactions_enabled
          if (amount.to_f < 0 and amount.to_f.abs <= self.club_cash_amount) or amount.to_f > 0
            cct = ClubCashTransaction.new(:amount => amount, :description => description)
            cct.member = self
            raise "Could not save club cash transaction" unless cct.valid? and self.valid?
            self.club_cash_amount = self.club_cash_amount + amount.to_f
            self.save(:validate => false)
            message = "#{cct.amount.to_f.abs} club cash was successfully #{ amount.to_f >= 0 ? 'added' : 'deducted' }."+(description.blank? ? '' : ". Concept: #{description}")
            if amount.to_f > 0
              Auditory.audit(agent, cct, message, self, Settings.operation_types.add_club_cash)
            elsif amount.to_f < 0 and amount.to_f.abs == club_cash_amount 
              Auditory.audit(agent, cct, message, self, Settings.operation_types.reset_club_cash)
            elsif amount.to_f < 0 
              Auditory.audit(agent, cct, message, self, Settings.operation_types.deducted_club_cash)
            end
            answer = { :message => message, :code => Settings.error_codes.success }
          else
            answer[:message] = "You can not deduct #{amount.to_f.abs} because the member only has #{self.club_cash_amount} club cash."
            answer[:errors] = { :amount => "Club cash amount is greater that member's actual club cash." }
          end
        else
          Drupal::UserPoints.new(self).create!({:amount => amount, :description => description})
          message = last_sync_error || "Club cash processed at drupal correctly."
          if self.last_sync_error.nil?
            answer = { :message => message, :code => Settings.error_codes.success }
          else
            answer = { :message => last_sync_error, :code => Settings.error_codes.club_cash_transaction_not_successful }
          end
          answer[:message] = I18n.t('error_messages.drupal_error_sync') if message.blank?
          Auditory.audit(agent, self, answer[:message], self, Settings.operation_types.remote_club_cash_transaction)
        end
      rescue Exception => e
        answer[:errors] = cct.errors_merged(self) unless cct.nil?
        Airbrake.notify(:error_class => 'Club cash Transaction', :error_message => e.to_s + answer[:message], :parameters => { :member => self.inspect, :amount => amount, :description => description, :club_cash_transaction => (cct.inspect unless cct.nil?) })
        answer[:message] = I18n.t('error_messages.airbrake_error_message')
        raise ActiveRecord::Rollback
      end
    end
    answer
  end

  def blacklist(agent, reason)
    answer = { :message => "Member already blacklisted", :success => false }
    unless self.blacklisted?
      Member.transaction do 
        begin
          self.blacklisted = true
          self.save(:validate => false)
          message = "Blacklisted member and all its credit cards. Reason: #{reason}."
          Auditory.audit(agent, self, message, self, Settings.operation_types.blacklisted)
          self.credit_cards.each { |cc| cc.blacklist }
          unless self.lapsed?
            self.cancel! Time.zone.now, "Automatic cancellation"
            self.set_as_canceled!
          end
          answer = { :message => message, :code => Settings.error_codes.success }
        rescue Exception => e
          Airbrake.notify(:error_class => "Member::blacklist", :error_message => e, :parameters => { :member => self.inspect })
          answer = { :message => I18n.t('error_messages.airbrake_error_message'), :success => Settings.error_codes.member_could_no_be_blacklisted }
          raise ActiveRecord::Rollback
        end
      end
    end
    answer
  end
  ###################################################################

  def update_member_data_by_params(params)
    [ :first_name, :last_name, :address, :state, :city, :country, :zip,
      :email, :birth_date, :gender,
      :phone_country_code, :phone_area_code, :phone_local_number, 
      :member_group_type_id, :preferences, :external_id ].each do |key|
          self.send("#{key}=", params[key]) if params.include? key
    end
    self.type_of_phone_number = params[:type_of_phone_number].to_s.downcase if params.include? :type_of_phone_number
  end

  def chargeback!(transaction_chargebacked, args)
    trans = Transaction.new_chargeback(transaction_chargebacked, args)
    self.blacklist nil, "Chargeback - "+args[:reason]
  end

  def cancel!(cancel_date, message, current_agent = nil)
    unless message.blank?
      if cancel_date.to_date >= Time.zone.now.to_date
        if self.cancel_date == cancel_date
          answer = { :message => "Cancel date is already set to that date", :code => Settings.error_codes.wrong_data }
        else
          if can_be_canceled?
            self.current_membership.update_attribute :cancel_date, cancel_date
            answer = { :message => "Member cancellation scheduled to #{cancel_date} - Reason: #{message}", :code => Settings.error_codes.success }
            Auditory.audit(current_agent, self, answer[:message], self, Settings.operation_types.future_cancel)
          else
            answer = { :message => "Member is not in cancelable status.", :code => Settings.error_codes.cancel_date_blank }
          end
        end
      else
        answer = { :message => "Cancellation date cannot be less or equal than today.", :code => Settings.error_codes.wrong_data }
      end
    else 
      answer = { :message => "Reason missing. Please, make sure to provide a reason for this cancelation.", :code => Settings.error_codes.cancel_reason_blank }
    end 
    return answer
  end
  
  def set_wrong_address(agent, reason, set_fulfillments = true)
    if self.wrong_address.nil?
      if self.update_attribute(:wrong_address, reason)
        if set_fulfillments
          self.fulfillments.where_to_set_bad_address.each do |fulfillment| 
            former_status = fulfillment.status
            fulfillment.set_as_bad_address
            fulfillment.audit_status_transition(agent,former_status,nil)
          end
        end
        message = "Address #{self.full_address} is undeliverable. Reason: #{reason}"
        Auditory.audit(agent, self, message, self, Settings.operation_types.member_address_set_as_undeliverable)
        { :message => message, :code => Settings.error_codes.success }
      else
        message = I18n.t('error_messages.member_set_wrong_address_error', :errors => self.errors.inspect)
        {:message => message, :code => Settings.error_codes.member_set_wrong_address_error}
      end
    else
      message = I18n.t('error_messages.member_set_wrong_address_error', :errors => '')
      { :message => message, :code => Settings.error_codes.member_already_set_wrong_address }
    end
  end

def self.sync_members_to_pardot
    index = 0
    base = Member.where("date(updated_at) >= ? ", Time.zone.now.yesterday.to_date).limit(2000)
    Rails.logger.info " *** [#{I18n.l(Time.zone.now, :format =>:dashed)}] Starting members:sync_members_to_pardot, processing #{base.count} members"
    base.each do |member|
      tz = Time.zone.now
      begin
        index = index+1
        Rails.logger.info "  *[#{index}] processing member ##{member.id}"
        member.sync_to_pardot unless member.pardot_member.nil?
      rescue Exception => e
        Airbrake.notify(:error_class => "Pardot::MemberSync", :error_message => "#{e.to_s}\n\n#{$@[0..9] * "\n\t"}", :parameters => { :member => member.inspect })
        Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
      end
      Rails.logger.info "    ... took #{Time.zone.now - tz} for member ##{member.id}"
    end
  end    

  # Method used from rake task and also from tests!
  def self.bill_all_members_up_today
    file = File.open("/tmp/bill_all_members_up_today_#{Rails.env}.lock", File::RDWR|File::CREAT, 0644)
    file.flock(File::LOCK_EX)
    index = 0
    base = Member.where("next_retry_bill_date <= ? and club_id IN (select id from clubs where billing_enable = true) and status NOT IN ('applied','lapsed')", Time.zone.now).
           limit(2000)    
    Rails.logger.info " *** [#{I18n.l(Time.zone.now, :format =>:dashed)}] Starting members:billing rake task, processing #{base.count} members"
    base.each do |member| 
      tz = Time.zone.now
      begin
        index = index+1 
        Rails.logger.info "  *[#{index}] processing member ##{member.id} nbd: #{member.next_retry_bill_date}"
        member.bill_membership
      rescue Exception => e
        Airbrake.notify(:error_class => "Billing::Today", :error_message => "#{e.to_s}\n\n#{$@[0..9] * "\n\t"}", :parameters => { :member => member.inspect, :credit_card => member.active_credit_card.inspect })
        Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
      end
      Rails.logger.info "    ... took #{Time.zone.now - tz} for member ##{member.id}"
    end
    file.flock(File::LOCK_UN)
  end

  def self.refresh_autologin
    index = 0
    Member.find_each do |member|
      begin
        index = index+1
        Rails.logger.info "   *[#{index}] processing member ##{member.id}"
        member.refresh_autologin_url!
      rescue
        Airbrake.notify error_class: "Members::Members", 
          error_message: "#{e.to_s}\n\n#{$@[0..9] * "\n\t"}", :parameters => { :member => member.inspect }
        Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
      end
    end
  end

  def self.send_pillar_emails
    # TODO: join EmailTemplate and Member querys
    base = EmailTemplate.where(["template_type = ? ", :pillar])
    Rails.logger.info " *** [#{I18n.l(Time.zone.now, :format =>:dashed)}] Starting members:send_pillar_emails rake task, processing #{base.count} templates"
    index_template = 0
    index_member = 0
    base.find_in_batches do |group|
      group.each do |template| 
        tz = Time.zone.now
        begin
          index_template = index_template+1 
          Rails.logger.info "  *[#{index_template}] processing template ##{template.id}"
          Membership.find_in_batches(:conditions => 
              [ " date(join_date) = ? AND terms_of_membership_id = ? AND status IN (?) ", 
                (Time.zone.now - template.days_after_join_date.days).to_date, 
                template.terms_of_membership_id, ['active', 'provisional'] ]) do |group1|
            group1.each do |membership| 
              begin
                index_member = index_member+1
                Rails.logger.info "  *[#{index_member}] processing member ##{membership.member_id}"
                Communication.deliver!(template, membership.member)
              rescue Exception => e
                Airbrake.notify(:error_class => "Members::SendPillar", :error_message => "#{e.to_s}\n\n#{$@[0..9] * "\n\t"}", :parameters => { :template => template.inspect, :membership => membership.inspect })
                Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
              end
            end
          end
        rescue Exception => e
          Airbrake.notify(:error_class => "Members::SendPillar", :error_message => "#{e.to_s}\n\n#{$@[0..9] * "\n\t"}", :parameters => { :template => template.inspect })
          Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
        end
        Rails.logger.info "    ... took #{Time.zone.now - tz} for template ##{template.id}"
      end
    end
  end

  # Method used from rake task and also from tests!
  def self.reset_club_cash_up_today
    index = 0
    base = Member.includes(:club).where("date(club_cash_expire_date) <= ? AND clubs.api_type != 'Drupal::Member' AND club_cash_enable = true", Time.zone.now.to_date).limit(2000)
    Rails.logger.info " *** [#{I18n.l(Time.zone.now, :format =>:dashed)}] Starting members:reset_club_cash_up_today rake task, processing #{base.count} members"
    base.each do |member|
      tz = Time.zone.now
      begin
        index = index+1
        Rails.logger.info "  *[#{index}] processing member ##{member.id}"
        member.reset_club_cash
      rescue Exception => e
        Airbrake.notify(:error_class => "Member::ClubCash", :error_message => "#{e.to_s}\n\n#{$@[0..9] * "\n\t"}", :parameters => { :member => member.inspect })
        Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
      end
      Rails.logger.info "    ... took #{Time.zone.now - tz} for member ##{member.id}"
    end
  end

  # Method used from rake task and also from tests!
  def self.cancel_all_member_up_today
    index = 0
    base =  Member.joins(:current_membership).where("date(memberships.cancel_date) <= ? AND memberships.status != ? ", Time.zone.now.to_date, 'lapsed')
    Rails.logger.info " *** [#{I18n.l(Time.zone.now, :format =>:dashed)}] Starting members:cancel_all_member_up_today rake task, processing #{base.count} members"
    base.each do |member| 
      tz = Time.zone.now
      begin
        index = index+1
        Rails.logger.info "  *[#{index}] processing member ##{member.id}"
        Member.find(member.id).set_as_canceled!
      rescue Exception => e
        Airbrake.notify(:error_class => "Members::Cancel", :error_message => "#{e.to_s}\n\n#{$@[0..9] * "\n\t"}", :parameters => { :member => member.inspect })
        Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
      end
      Rails.logger.info "    ... took #{Time.zone.now - tz} for member ##{member.id}"
    end
  end

  def self.process_sync 
    base = Member.where("status = 'lapsed' AND api_id != ''")
    Rails.logger.info " *** [#{I18n.l(Time.zone.now, :format =>:dashed)}] Starting members:process_sync rake task with members lapsed and api_id not null, processing #{base.count} members"
    base.find_in_batches do |group|
      group.each do |member|
        member.api_member.destroy!
        if member.last_sync_error.include?("There is no user with ID")
          member.update_attribute :api_id, nil
        end
        Auditory.audit(nil, member, "Member's drupal account destroyed by batch script", member, Settings.operation_types.member_drupal_account_destroyed_batch)
      end
    end
    base = Member.where("sync_status IN ('with_error', 'not_synced') and status != 'lapsed' ").limit(2000)
    Rails.logger.info " *** [#{I18n.l(Time.zone.now, :format =>:dashed)}] Starting members:process_sync rake task with members not_synced or with_error, processing #{base.count} members"
    index = 0
    base.each do |member|
      index = index+1
      Rails.logger.info "  *[#{index}] processing member ##{member.id}"
      api_m = member.api_member
      unless api_m.nil?
        if api_m.save!(force: true)
          unless member.last_sync_error_at
            Auditory.audit(nil, member, "Member synchronized by batch script", member, Settings.operation_types.member_drupal_account_synced_batch)
          end
        end
      end
    end       
  end

  def self.process_email_sync_error
    member_list = []
    base = Member.where("sync_status = 'with_error' AND last_sync_error like 'The e-mail address%is already taken.%'")
    Rails.logger.info " *** [#{I18n.l(Time.zone.now, :format =>:dashed)}] Starting members:process_email_sync_error rake task, processing #{base.count} members"
    base.find_in_batches do |group|
      group.each do |member|
        member_list << member
      end
    end  
    Notifier.members_with_duplicated_email_sync_error(member_list).deliver!
  end

  def self.send_happy_birthday
    today = Time.zone.now.to_date
    index = 0
    base = Member.billable.where(" birth_date IS NOT NULL and DAYOFMONTH(birth_date) = ? and MONTH(birth_date) = ? ", 
      today.day, today.month)
    Rails.logger.info " *** [#{I18n.l(Time.zone.now, :format =>:dashed)}] Starting members:send_happy_birthday rake task, processing #{base.count} members"
    base.find_in_batches do |group|
      group.each do |member| 
        tz = Time.zone.now
        begin
          index = index+1
          Rails.logger.info "  *[#{index}] processing member ##{member.id}"
          Communication.deliver!(:birthday, member)
        rescue Exception => e
          Airbrake.notify(:error_class => "Members::send_happy_birthday", :error_message => "#{e.to_s}\n\n#{$@[0..9] * "\n\t"}", :parameters => { :member => member.inspect })
          Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
        end
        Rails.logger.info "    ... took #{Time.zone.now - tz} for member ##{member.id}"
      end
    end
  end

  def self.send_prebill
    index = 0
    base = Member.where([" date(next_retry_bill_date) = ? AND recycled_times = 0 AND terms_of_memberships.installment_amount != 0.0", 
      (Time.zone.now + 7.days).to_date ]).includes(:current_membership => :terms_of_membership) 
    base.find_in_batches do |group|
      group.each do |member| 
        tz = Time.zone.now
        begin
          index = index + 1 
          Rails.logger.info "  *[#{index}] processing member ##{member.id}"
          member.send_pre_bill
        rescue Exception => e
          Airbrake.notify(:error_class => "Billing::SendPrebill", :error_message => "#{e.to_s}\n\n#{$@[0..9] * "\n\t"}", :parameters => { :member => member.inspect })
          Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
        end
        Rails.logger.info "    ... took #{Time.zone.now - tz} for member ##{member.id}"
      end
    end
  end

  def self.supported_states(country='US')
    if country == 'US'
      Carmen::Country.coded('US').subregions.select{ |s| %w{AK AL AR AZ CA CO CT DE FL 
        GA HI IA ID IL IN KS KY LA MA MD ME MI MN MO MS MT NC ND NE NH  NJ NM NV NY OH 
        OK OR PA RI SC SD TN TX UT VA VI VT WA WI WV WY}.include?(s.code) }
    else
      Carmen::Country.coded('CA').subregions
    end
  end

  def validate_if_credit_card_already_exist(tom, number, new_year, new_month, only_validate = true, allow_cc_blank = false, current_agent = nil)
    answer = { :message => "Credit card valid", :code => Settings.error_codes.success}
    family_memberships_allowed = tom.club.family_memberships_allowed
    new_credit_card = CreditCard.new(:number => number, :expire_month => new_month, :expire_year => new_year)
    new_credit_card.get_token(tom.payment_gateway_configuration, first_name, last_name)
    credit_cards = new_credit_card.token.nil? ? [] : CreditCard.joins(:member).where(:token => new_credit_card.token, :members => { :club_id => club.id } )

    if credit_cards.empty? or allow_cc_blank
      unless only_validate
        answer = add_new_credit_card(new_credit_card, current_agent)
      end
    # credit card is blacklisted
    elsif not credit_cards.select { |cc| cc.blacklisted? }.empty? 
      answer = { :message => I18n.t('error_messages.credit_card_blacklisted', :cs_phone_number => self.club.cs_phone_number), :code => Settings.error_codes.credit_card_blacklisted, :errors => { :number => "Credit card is blacklisted" }}
    # is this credit card already of this member and its already active?
    elsif not credit_cards.select { |cc| cc.member_id == self.id and cc.active }.empty? 
      unless only_validate
        answer = active_credit_card.update_expire(new_year, new_month, current_agent) # lets update expire month
      end
    # is this credit card already of this member but its inactive? and we found another credit card assigned to another member but in active status?
    elsif not family_memberships_allowed and not credit_cards.select { |cc| cc.member_id == self.id and not cc.active }.empty? and not credit_cards.select { |cc| cc.member_id != self.id and cc.active }.empty?
      answer = { :message => I18n.t('error_messages.credit_card_in_use', :cs_phone_number => self.club.cs_phone_number), :code => Settings.error_codes.credit_card_in_use, :errors => { :number => "Credit card is already in use" }}
    # is this credit card already of this member but its inactive? and we found another credit card assigned to another member but in inactive status?
    elsif not credit_cards.select { |cc| cc.member_id == self.id and not cc.active }.empty? and (family_memberships_allowed or credit_cards.select { |cc| cc.member_id != self.id and cc.active }.empty?)
      unless only_validate
        new_active_credit_card = CreditCard.find credit_cards.select { |cc| cc.member_id == self.id }.first.id
        CreditCard.transaction do 
          begin
            answer = new_active_credit_card.update_expire(new_year, new_month, current_agent) # lets update expire month
            if answer[:code] == Settings.error_codes.success
              # activate new credit card ONLY if expire date was updated.
              new_active_credit_card.set_as_active!
            end
          rescue Exception => e
            Airbrake.notify(:error_class => "Members::update_credit_card_from_drupal", :error_message => "#{e.to_s}\n\n#{$@[0..9] * "\n\t"}", :parameters => { :new_active_credit_card => new_active_credit_card.inspect, :member => self.inspect })
            raise ActiveRecord::Rollback
          end
        end
      end
    # its not my credit card. its from another member. the question is. can I use it?
    elsif family_memberships_allowed or credit_cards.select { |cc| cc.active }.empty? 
      unless only_validate
        answer = add_new_credit_card(new_credit_card, current_agent)
      end
    else
      answer = { :message => I18n.t('error_messages.credit_card_in_use', :cs_phone_number => self.club.cs_phone_number), :code => Settings.error_codes.credit_card_in_use, :errors => { :number => "Credit card is already in use" }}
    end
    answer
  end

  def update_credit_card_from_drupal(credit_card, current_agent = nil)
    return { :code => Settings.error_codes.success } if credit_card.nil? || credit_card.empty?
    new_year, new_month, new_number = credit_card[:expire_year], credit_card[:expire_month], nil

    if self.blacklisted
      return { :code => Settings.error_codes.blacklisted, :message => I18n.t('error_messages.member_set_as_blacklisted') }
    end

    # Drupal sends X when member does not change the credit card number      
    if credit_card[:number].blank?
      { :code => Settings.error_codes.invalid_credit_card, :message => I18n.t('error_messages.invalid_credit_card'), :errors => { :number => "Credit card is blank." }}
    elsif credit_card[:number].include?('X')
      if active_credit_card.last_digits.to_s == credit_card[:number][-4..-1].to_s # lets update expire month
        active_credit_card.update_expire(new_year, new_month, current_agent)
      else # do not update nothing, credit cards do not match or its expired
        { :code => Settings.error_codes.invalid_credit_card, :message => I18n.t('error_messages.invalid_credit_card'), :errors => { :number => "Credit card do not match the active one." }}
      end
    else # drupal or CS sends the complete credit card number.
      validate_if_credit_card_already_exist(terms_of_membership, credit_card[:number], new_year, new_month, false, false, current_agent)
    end
  end

  def add_new_credit_card(new_credit_card, current_agent = nil)
    answer = {}
    CreditCard.transaction do 
      begin
        new_credit_card.member = self
        if new_credit_card.errors.size == 0
          new_credit_card.save!
          message = "Credit card #{new_credit_card.last_digits} added and activated."
          Auditory.audit(current_agent, new_credit_card, message, self, Settings.operation_types.credit_card_added)
          answer = { :code => Settings.error_codes.success, :message => message }
          new_credit_card.set_as_active!
        else
          answer = { :code => Settings.error_codes.invalid_credit_card, :message => I18n.t('error_messages.invalid_credit_card'), :errors => new_credit_card.errors.to_hash }
        end        
      rescue Exception => e
        answer = { :errors => e, :message => I18n.t('error_messages.airbrake_error_message'), :code => Settings.error_codes.invalid_credit_card }
        Airbrake.notify(:error_class => "Member:update_credit_card", :error_message => e, :parameters => { :member => self.inspect, :credit_card => new_credit_card.inspect })
        raise ActiveRecord::Rollback
      end
    end
    answer
  end

  def desnormalize_preferences
    if self.preferences.present?
      self.preferences.each do |key, value|
        pref = MemberPreference.find_or_create_by_member_id_and_club_id_and_param(self.id, self.club_id, key)
        pref.value = value
        pref.save
      end
    end
  end
  handle_asynchronously :desnormalize_preferences

  def sync_to_pardot(options = {})
    time_elapsed = Benchmark.ms do
      pardot_member.save!(options) unless pardot_member.nil?
    end
    logger.info "Pardot::sync took #{time_elapsed}ms"
  rescue Exception => e
    Airbrake.notify(:error_class => "Pardot:sync", :error_message => e, :parameters => { :member => self.inspect })
  end

  private
    def schedule_renewal
      new_bill_date = self.bill_date + eval(terms_of_membership.installment_type)
      # refs #15935
      if terms_of_membership.monthly? and self.recycled_times > 1
        new_bill_date = Time.zone.now + eval(terms_of_membership.installment_type)
      end
      self.current_membership.increment!(:quota, terms_of_membership.quota)
      self.recycled_times = 0
      self.bill_date = new_bill_date
      self.next_retry_bill_date = new_bill_date
      self.save(:validate => false)
      Auditory.audit(nil, self, "Renewal scheduled. NBD set #{new_bill_date.to_date}", self, Settings.operation_types.renewal_scheduled)
    end

    def set_status_on_enrollment!(agent, trans, amount, info)
      operation_type = Settings.operation_types.enrollment_billing
      description = 'enrolled'

      # Member approval need it?
      if terms_of_membership.needs_enrollment_approval?
        self.set_as_applied!
        # is a recovery?
        if self.lapsed?
          description = 'recovered pending approval'
          operation_type = Settings.operation_types.recovery_needs_approval
        else
          description = 'enrolled pending approval'
          operation_type = Settings.operation_types.enrollment_needs_approval
        end
      elsif self.lapsed? # is a recovery?
        self.recovered!
        description = 'recovered'
        operation_type = Settings.operation_types.recovery
      else      
        self.set_as_provisional! # set join_date
      end

      message = "Member #{description} successfully $#{amount} on TOM(#{terms_of_membership.id}) -#{terms_of_membership.name}-"
      Auditory.audit(agent, 
        (trans.nil? ? terms_of_membership : trans), 
        message, self, operation_type)
      
      message
    end

    def fulfillments_products_to_send
      self.current_membership.enrollment_info.product_sku ? self.current_membership.enrollment_info.product_sku.split(',') : []
    end

    def record_date
      self.member_since_date = Time.zone.now
    end

    def cancellation
      self.cancel_member_at_remote_domain
      if (Time.zone.now.to_date - join_date.to_date).to_i < Settings.days_to_wait_to_cancel_fulfillments
        fulfillments.where_cancellable.each do |fulfillment| 
          former_status = fulfillment.status
          fulfillment.set_as_canceled
          fulfillment.audit_status_transition(nil,former_status,nil)
        end
      end
      self.next_retry_bill_date = nil
      self.bill_date = nil
      self.recycled_times = 0
      self.save(:validate => false)
      Communication.deliver!(:cancellation, self)
      Auditory.audit(nil, current_membership, "Member canceled", self, Settings.operation_types.cancel)
    end

    def propagate_membership_data
      self.current_membership.update_attribute :status, status
    end

    def set_decline_strategy(trans)
      # soft / hard decline
      type = terms_of_membership.installment_type
      decline = DeclineStrategy.find_by_gateway_and_response_code_and_installment_type_and_credit_card_type(trans.gateway.downcase, 
                  trans.response_code, type, trans.cc_type) || 
                DeclineStrategy.find_by_gateway_and_response_code_and_installment_type_and_credit_card_type(trans.gateway.downcase, 
                  trans.response_code, type, "all")
      cancel_member = false

      if decline.nil?
        # we must send an email notifying about this error. Then schedule this job to run in the future (1 month)
        message = "Billing error. No decline rule configured: #{trans.response_code} #{trans.gateway}: #{trans.response_result}"
        self.next_retry_bill_date = Time.zone.now + eval(Settings.next_retry_on_missing_decline)
        self.save(:validate => false)
        Airbrake.notify(:error_class => "Decline rule not found TOM ##{terms_of_membership.id}", 
          :error_message => "MID ##{self.id} TID ##{trans.id}. Message: #{message}. CC type: #{trans.cc_type}. " + 
            "Campaign type: #{type}. We have scheduled this billing to run again in #{Settings.next_retry_on_missing_decline} days.",
          :parameters => { :member => self.inspect })
        if self.recycled_times < Settings.number_of_retries_on_missing_decline
          Auditory.audit(nil, trans, message, self, Settings.operation_types.membership_billing_without_decline_strategy)
          increment!(:recycled_times, 1)
          return message
        end
        cancel_member = true
      else
        trans.update_attribute :decline_strategy_id, decline.id
        if decline.hard_decline?
          message = "Hard Declined: #{trans.response_code} #{trans.gateway}: #{trans.response_result}"
          cancel_member = true
        else
          message="Soft Declined: #{trans.response_code} #{trans.gateway}: #{trans.response_result}"
          self.next_retry_bill_date = decline.days.days.from_now
          if self.recycled_times > (decline.limit-1)
            message = "Soft recycle limit (#{self.recycled_times}) reached: #{trans.response_code} #{trans.gateway}: #{trans.response_result}"
            cancel_member = true
          end
        end
      end
      self.save(:validate => false)
      if cancel_member
        Auditory.audit(nil, trans, message, self, Settings.operation_types.membership_billing_hard_decline)
        self.cancel! Time.zone.now, "HD cancellation"
        set_as_canceled!
        Communication.deliver!(:hard_decline, self)
      else
        Auditory.audit(nil, trans, message, self, Settings.operation_types.membership_billing_soft_decline)
        increment!(:recycled_times, 1)
        Communication.deliver!(:soft_decline, self)
      end
      message
    end

    def asyn_desnormalize_preferences(opts = {})
      self.desnormalize_preferences if opts[:force] || self.changed.include?('preferences') 
    end

    def wrong_address_logic
      if not (self.changed & ['address', 'state', 'city', 'zip', 'country']).empty? and not self.wrong_address.nil?
        self.wrong_address = nil
      end
      if self.changed.include?('wrong_address') and self.wrong_address.nil?
        self.fulfillments.where_bad_address.each do |s| 
          answer = s.decrease_stock! 
          if answer[:code] == Settings.error_codes.success
            s.update_status( nil, 'not_processed', "Recovered from member unseted wrong address" )
          else
            s.update_status( nil, 'out_of_stock', "Recovered from member unseted wrong address" )
          end
        end
      end
    end
end
