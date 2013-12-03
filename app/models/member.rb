# encoding: utf-8
class Member < ActiveRecord::Base
  extend Extensions::Member::CountrySpecificValidations
#  extend Extensions::Member::DateSpecificValidations
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
  has_many :member_additional_data
  has_many :memberships, :order => "created_at DESC"
  belongs_to :current_membership, :class_name => 'Membership'
  
  # TODO: should we use delegate??
  delegate :terms_of_membership, :to => :current_membership
  # attr :terms_of_membership_id # is it necesarilly??? 
  delegate :terms_of_membership_id, :to => :current_membership
  delegate :join_date, :to => :current_membership
  delegate :cancel_date, :to => :current_membership
  delegate :time_zone, :to => :club
  ##### 

  attr_accessible :address, :bill_date, :city, :country, :description, 
      :email, :external_id, :first_name, :phone_country_code, :phone_area_code, :phone_local_number, 
      :last_name, :next_retry_bill_date, 
      :bill_date, :state, :zip, :member_group_type_id, :blacklisted, :wrong_address,
      :wrong_phone_number, :credit_cards_attributes, :birth_date,
      :gender, :type_of_phone_number, :preferences

  serialize :preferences, JSON
  serialize :additional_data, JSON

  before_create :record_date
  before_save :wrong_address_logic

  after_update :after_save_sync_to_remote_domain
  after_destroy 'cancel_member_at_remote_domain'
  after_create 'asyn_desnormalize_preferences(force: true)'
  after_update :asyn_desnormalize_preferences
  after_save :after_marketing_tool_sync
  

  # skip_api_sync wont be use to prevent remote destroy. will be used to prevent creates/updates
  def cancel_member_at_remote_domain
    api_member.destroy! unless api_member.nil? || api_id.nil?
  rescue Exception => e
    # refs #21133
    # If there is connectivity problems or data errors with drupal. Do not stop enrollment!! 
    # Because maybe we have already bill this member.
    Auditory.report_issue("Member:account_cancel:sync", e, { :member => self.inspect })
  end
  handle_asynchronously :cancel_member_at_remote_domain, :queue => :drupal_queue

  def after_save_sync_to_remote_domain
    unless @skip_api_sync || api_member.nil?
      api_member.save!
    end
  rescue Exception => e
    # refs #21133
    # If there is connectivity problems or data errors with drupal. Do not stop enrollment!! 
    # Because maybe we have already bill this member.
    Auditory.report_issue("Member:drupal_sync", e, { :member => self.inspect })
  end

  validates :country, 
    presence:                    true, 
    length:                      { is: 2, allow_nil: true },
    inclusion:                   { within: self.supported_countries }
  country_specific_validations!
  validates :birth_date, :birth_date => true
  validates :email, :email => true

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
  scope :with_next_retry_bill_date, lambda { |value| where('members.next_retry_bill_date BETWEEN ? AND ?', value.to_date.to_time_in_current_zone.beginning_of_day, value.to_date.to_time_in_current_zone.end_of_day) unless value.blank? }
  scope :with_phone_country_code, lambda { |value| where('members.phone_country_code = ?', value.strip) unless value.blank? }
  scope :with_phone_area_code, lambda { |value| where('members.phone_area_code = ?', value.strip) unless value.blank? }
  scope :with_phone_local_number, lambda { |value| where('members.phone_local_number = ?', value.strip) unless value.blank? }
  scope :with_first_name_like, lambda { |value| where('members.first_name like ?', '%'+value.strip+'%') unless value.blank? }
  scope :with_last_name_like, lambda { |value| where('members.last_name like ?', '%'+value.strip+'%') unless value.blank? }
  scope :with_address_like, lambda { |value| where('members.address like ?', '%'+value.strip+'%') unless value.blank? }
  scope :with_city_like, lambda { |value| where('members.city like ?', '%'+value.strip+'%') unless value.blank? }
  scope :with_country_like, lambda { |value| where('members.country like ?', value) unless value.blank? }
  scope :with_state_like, lambda { |value| where('members.state like ?', value) unless value.blank? }
  scope :with_zip, lambda { |value| where('members.zip like ?', '%'+value.strip+'%') unless value.blank? }
  scope :with_email_like, lambda { |value| where('members.email like ?', '%'+value.strip+'%') unless value.blank? }
  scope :with_credit_card_last_digits, lambda{ |value| joins(:credit_cards).where('credit_cards.last_digits = ?', value.strip) unless value.blank? }
  scope :with_credit_card_token, lambda{ |value| joins(:credit_cards).where('credit_cards.token = ?', value) unless value.blank? }
  scope :with_member_notes, lambda{ |value| joins(:member_notes).where('member_notes.description like ?', '%'+value.strip+'%') unless value.blank? }
  scope :with_external_id, lambda{ |value| where("members.external_id like ?",'%'+value.strip+'%') unless value.blank? }
  scope :needs_approval, lambda{ |value| where('members.status = ?', 'applied') unless value == '0' }
  scope :with_billed_date_from, lambda{ |value| joins(:transactions).where('date(transactions.created_at) >= ?', value) unless value.blank? }
  scope :with_billed_date_to, lambda{ |value| joins(:transactions).where('date(transactions.created_at) <= ?', value) unless value.blank? }


  state_machine :status, :initial => :none, :action => :save_state do
    ###### member gets applied =====>>>>
    after_transition :lapsed => 
                        :applied, :do => [:set_join_date, :send_recover_needs_approval_email]
    after_transition [ :none, :provisional, :active ] => # none is new join. provisional and active are save the sale
                        :applied, :do => [:set_join_date, :send_active_needs_approval_email]
    ###### <<<<<<========
    ###### member gets active =====>>>>
    after_transition :provisional => 
                        :active, :do => [:assign_first_club_cash]
    after_transition :active => 
                    :active, :do => 'assign_club_cash'
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
                        :lapsed, :do => [:cancellation, 'nillify_club_cash']
    after_transition :applied => 
                        :lapsed, :do => [:set_member_as_rejected, :send_rejection_communication]
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

  # Sends the request mail to every representative to accept/reject the member.
  def send_active_needs_approval_email
    send_active_needs_approval_email_dj
  end
  def send_active_needs_approval_email_dj
    representatives = ClubRole.find_all_by_club_id_and_role(self.club_id,'representative')
    emails = representatives.collect { |representative| representative.agent.email }.join(',')
    Notifier.active_with_approval(emails,self).deliver!
  end
  handle_asynchronously :send_active_needs_approval_email_dj, :queue => :email_queue

  # Sends the request mail to every representative to accept/reject the member.
  def send_recover_needs_approval_email
    send_recover_needs_approval_email_dj
  end
  def send_recover_needs_approval_email_dj
    representatives = ClubRole.find_all_by_club_id_and_role(self.club_id,'representative')
    emails = representatives.collect { |representative| representative.agent.email }.join(',')
    Notifier.recover_with_approval(emails,self).deliver!
  end
  handle_asynchronously :send_recover_needs_approval_email_dj, :queue => :email_queue

  # Increment reactivation times upon recovering a member. (From lapsed to provisional or applied)
  def increment_reactivations
    increment!(:reactivation_times, 1)
  end

  def additional_data_form
    "Form#{club_id}".constantize rescue nil
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

  def send_rejection_communication
    Communication.deliver!(:rejection, self)
  end

  # Sends the fulfillment, and it settes bill_date and next_retry_bill_date according to member's terms of membership.
  def schedule_first_membership(set_join_date, skip_send_fulfillment = false, nbd_update_for_sts = false, skip_add_club_cash = false)
    membership = current_membership
    if set_join_date
      membership.update_attribute :join_date, Time.zone.now
    end    

    send_fulfillment unless skip_send_fulfillment
    
    if not nbd_update_for_sts and is_billing_expected?
      self.bill_date = membership.join_date + terms_of_membership.provisional_days.days
      self.next_retry_bill_date = membership.join_date + terms_of_membership.provisional_days.days
    end
    self.save(:validate => false)
    assign_club_cash('club cash on enroll', true) unless skip_add_club_cash
  end

  # Changes next bill date.
  def change_next_bill_date(next_bill_date, current_agent = nil)
    if not is_billing_expected?
      errors = { :member => 'is not expected to get billed.' }
      answer = { :message => I18n.t('error_messages.not_expecting_billing'), :code => Settings.error_codes.member_not_expecting_billing, :errors => errors }
    elsif not self.can_change_next_bill_date?
      errors = { :member => 'is not in billable status' }
      answer = { :message => I18n.t('error_messages.unable_to_perform_due_member_status'), :code => Settings.error_codes.next_bill_date_blank, :errors => errors }
    elsif next_bill_date.blank?
      errors = { :next_bill_date => 'is blank' }
      answer = { :message => I18n.t('error_messages.next_bill_date_blank'), :code => Settings.error_codes.next_bill_date_blank, :errors => errors }
    elsif next_bill_date.to_datetime < Time.zone.now.to_date
      errors = { :next_bill_date => 'Is prior to actual date' }
      answer = { :message => "Next bill date should be older that actual date.", :code => Settings.error_codes.next_bill_date_prior_actual_date, :errors => errors }
    elsif self.valid? and not self.active_credit_card.expired?
      next_bill_date = next_bill_date.to_datetime.change(:offset => self.get_offset_related)
      self.next_retry_bill_date = next_bill_date
      self.bill_date = next_bill_date
      self.save(:validate => false)
      message = "Next bill date changed to #{next_bill_date.to_date}"
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
    Auditory.report_issue("Member:change_next_bill_date", e, { :member => self.inspect })
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
  def can_change_tom?
    self.active? or self.provisional?
  end

  def is_billing_expected?
    terms_of_membership.is_payment_expected
  end

  def status_enable_to_bill?
    self.active? or self.provisional?
  end

  # Returns true if member is active or provisional.
  def billing_enabled?
    status_enable_to_bill? and self.club.billing_enable
  end

  def membership_billing_enabled?
    billing_enabled? and is_billing_expected?
  end

  def manual_billing?
    self.manual_payment
  end

  def has_link_to_api?
    self.api_member and not self.lapsed?
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
    self.active? and self.recycled_times == 0
  end

  def last_refunded_amount
    # default order by is created_at ASC
    self.transactions.refunds.last.amount rescue 0.0
  end

  # Returns true if member is not blacklisted and not lapsed
  def can_be_blacklisted?
    !self.blacklisted?
  end

  def can_add_club_cash?
    if is_not_drupal?
      return true
    elsif not (self.api_id.blank? or self.api_id.nil?)
      return true
    end
    false
  end

  def can_change_next_bill_date?
    not self.applied? and not self.lapsed?
  end
  
  def has_been_sd_cc_expired?
    self.transactions.where('membership_id = ? AND transaction_type = "sale"', self.current_membership_id).order('created_at DESC').limit(self.recycled_times).each do |transaction|
      return true if transaction.is_response_code_cc_expired?
    end
    false
  end

  ###############################################

  def change_terms_of_membership(new_tom_id, operation_message, operation_type, agent = nil)
    if can_change_tom?
      new_tom = TermsOfMembership.find new_tom_id
      if new_tom.club_id == self.club_id
        if new_tom_id.to_i == terms_of_membership.id
          { :message => "Nothing to change. Member is already enrolled on that TOM.", :code => Settings.error_codes.nothing_to_change_tom }
        else
          prev_membership_id = current_membership.id
          new_tom = TermsOfMembership.find(new_tom_id)
          res = enroll(new_tom, self.active_credit_card, 0.0, agent, false, 0, self.current_membership.enrollment_info, true, true)
          if res[:code] == Settings.error_codes.success
            Auditory.audit(agent, new_tom, operation_message, self, operation_type)
            Membership.find(prev_membership_id).cancel_because_of_membership_change
          # update manually this fields because we cant cancel member
          end
          res
        end
      else
        { :message => "Tom(#{new_tom_id}) to change belongs to another club.", :code => Settings.error_codes.tom_to_downgrade_belongs_to_different_club }
      end
    else
      { :message => "Member status does not allows us to change the terms of membership.", :code => Settings.error_codes.member_status_dont_allow }
    end
  end

  def save_the_sale(new_tom_id, agent = nil)
    message = "Save the sale from TOM(#{self.terms_of_membership_id}) to TOM(#{new_tom_id})"
    change_terms_of_membership(new_tom_id, message, Settings.operation_types.save_the_sale, agent)
  end

  def downgrade_member
    new_tom_id = self.terms_of_membership.downgrade_tom_id
    message = "Downgraded member from TOM(#{self.terms_of_membership_id}) to TOM(#{new_tom_id})"
    answer = change_terms_of_membership(new_tom_id, message, Settings.operation_types.downgrade_member)
    if answer[:code] != Settings.error_codes.success
      Auditory.report_issue("DowngradeMember::Error", answer[:message], { :member => self.inspect, :answer => answer })
    end
    answer
  end

  # Recovers the member. Changes status from lapsed to applied or provisional (according to members term of membership.)
  def recover(new_tom, agent = nil, options = {})
    enrollment_info_params = options.merge({ 
      product_sku: self.current_membership.enrollment_info.product_sku, 
      mega_channel: EnrollmentInfo::CS_MEGA_CHANNEL,
      campaign_medium: EnrollmentInfo::CS_CAMPAIGN_MEDIUM,
      campaign_description: EnrollmentInfo::CS_CAMPAIGN_DESCRIPTION
    })
    enroll(new_tom, self.active_credit_card, 0.0, agent, true, 0, enrollment_info_params, true, false)
  end

  def has_problems_to_bill?
    if not self.club.billing_enable
      { :message => "Member's club is not allowing billing", :code => Settings.error_codes.member_club_dont_allow }
    elsif not status_enable_to_bill?
      { :message => "Member is not in a billing status.", :code => Settings.error_codes.member_status_dont_allow }
    elsif not is_billing_expected?
      { :message => "Member is not expected to get billed.", :code => Settings.error_codes.member_not_expecting_billing }
    else
      false
    end
  end

  def bill_membership
    trans = nil
    validation = has_problems_to_bill?
    if not validation and self.next_retry_bill_date.to_date <= Time.zone.now.to_date
      amount = terms_of_membership.installment_amount
      if terms_of_membership.payment_gateway_configuration.nil?
        message = "TOM ##{terms_of_membership.id} does not have a gateway configured."
        Auditory.audit(nil, terms_of_membership, message, self, Settings.operation_types.membership_billing_without_pgc)
        Auditory.report_issue("Billing", message, { :member => self.inspect, :membership => current_membership.inspect })
        { :code => Settings.error_codes.tom_wihtout_gateway_configured, :message => message }
      else
        credit_card = active_credit_card
        credit_card.recycle_expired_rule(recycled_times)
        trans = Transaction.obtain_transaction_by_gateway!(terms_of_membership.payment_gateway_configuration.gateway)
        trans.transaction_type = "sale"
        trans.response_result = I18n.t('error_messages.airbrake_error_message')
        trans.response = { message: message } 
        trans.prepare(self, credit_card, amount, terms_of_membership.payment_gateway_configuration, nil, nil, Settings.operation_types.membership_billing)
        answer = trans.process
        if trans.success?
          credit_card.save # lets update year if we recycle this member
          proceed_with_billing_logic(trans)
        else
          message = set_decline_strategy(trans)
          answer # TODO: should we answer set_decline_strategy message too?
        end
      end
    elsif not self.next_retry_bill_date.nil? and self.next_retry_bill_date > Time.zone.now
      { :message => "We haven't reach next bill date yet.", :code => Settings.error_codes.billing_date_not_reached }
    else
      validation
    end
  rescue Exception => e
    trans.update_attribute :operation_type, Settings.operation_types.membership_billing_with_error if trans
    Auditory.report_issue( "Billing:membership", e, { :member => self.inspect, :exception => e.to_s, :transaction => trans.inspect } )
    { :message => I18n.t('error_messages.airbrake_error_message'), :code => Settings.error_codes.membership_billing_error } 
  end

  def no_recurrent_billing(amount, description, type)
    trans = nil
    if amount.blank? or description.blank? or type.blank?
      answer = { :message =>"Amount, description and type cannot be blank.", :code => Settings.error_codes.wrong_data }
    elsif not Transaction::ONE_TIME_BILLINGS.include? type
      answer = { :message =>"Type should be 'one-time' or 'donation'.", :code => Settings.error_codes.wrong_data }
    elsif amount.to_f <= 0.0
      answer = { :message =>"Amount must be greater than 0.", :code => Settings.error_codes.wrong_data }
    else
      if billing_enabled?
        trans = Transaction.obtain_transaction_by_gateway!(terms_of_membership.payment_gateway_configuration.gateway)
        trans.transaction_type = "sale"
        trans.prepare_no_recurrent(self, active_credit_card, amount, terms_of_membership.payment_gateway_configuration, nil, nil, type)
        answer = trans.process
        if trans.success?
          message = "Member billed successfully $#{amount} Transaction id: #{trans.id}. Reason: #{description}"
          trans.update_attribute :response_result, trans.response_result+". Reason: #{description}"
          answer = { :message => message, :code => Settings.error_codes.success }
          Auditory.audit(nil, trans, answer[:message], self, trans.operation_type)
        else
          answer = { :message => trans.response_result, :code => Settings.error_codes.no_reccurent_billing_error }
          operation_type = trans.one_time_type? ? Settings.operation_types.no_recurrent_billing_with_error : Settings.operation_types.no_recurrent_billing_donation_with_error
          Auditory.audit(nil, trans, answer[:message], self, operation_type)
        end
      else
        if not self.club.billing_enable
          answer = { :message => "Member's club is not allowing billing", :code => Settings.error_codes.member_club_dont_allow }
        else
          answer = { :message => "Member is not in a billing status.", :code => Settings.error_codes.member_status_dont_allow }
        end
      end
    end
    answer
  rescue Exception => e
    trans.update_attribute :operation_type, Settings.operation_types.no_recurrent_billing_with_error if trans
    Auditory.report_issue("Billing:no_recurrent_billing", e, { :member => self.inspect, :amount => amount, :description => description })
    { :message => I18n.t('error_messages.airbrake_error_message'), :code => Settings.error_codes.no_reccurent_billing_error }
  end

  def manual_billing(amount, payment_type)
    trans = nil
    validation = has_problems_to_bill?
    if not validation
      if amount.blank? or payment_type.blank?
        answer = { :message => "Amount and payment type cannot be blank.", :code => Settings.error_codes.wrong_data }
      elsif amount.to_f < current_membership.terms_of_membership.installment_amount
        answer = { :message => "Amount to bill cannot be less than terms of membership installment amount.", :code => Settings.error_codes.manual_billing_with_less_amount_than_permitted }
      else
        trans = Transaction.new
        trans.transaction_type = "sale_manual_#{payment_type}"
        operation_type = Settings.operation_types["membership_manual_#{payment_type}_billing"]
        trans.prepare_for_manual(self, amount, operation_type)
        trans.process
        answer = proceed_with_manual_billing_logic(trans, operation_type)
        unless self.manual_payment
          self.manual_payment = true 
          self.save(:validate => false)
        end
        answer
      end
    else
      validation
    end
  rescue Exception => e
    logger.error e.inspect
    trans.update_attribute :operation_type, Settings.operation_types.manual_billing_with_error if trans
    Auditory.report_issue("Billing:manual_billing", e, { :member => self.inspect, :amount => amount, :payment_type => payment_type })
    { :message => I18n.t('error_messages.airbrake_error_message'), :code => Settings.error_codes.membership_billing_error } 
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
    credit_card_params = { number: '0000000000', expire_year: Time.zone.now.year, expire_month: Time.zone.now.month } if cc_blank
    club = tom.club

    unless club.billing_enable
      return { :message => I18n.t('error_messages.club_is_not_enable_for_new_enrollments', :cs_phone_number => club.cs_phone_number), :code => Settings.error_codes.club_is_not_enable_for_new_enrollments }      
    end
    
    member = Member.find_by_email_and_club_id(member_params[:email], club.id)
    # credit card exist? . we need this token for CreditCard.joins(:member) and enrollment billing.
    credit_card = CreditCard.new credit_card_params

    if member.nil?
      member = Member.new
      member.update_member_data_by_params member_params
      member.skip_api_sync! if member.api_id.present? || skip_api_sync
      member.club = club
      credit_card.get_token(tom.payment_gateway_configuration, member, cc_blank)
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
      credit_card.get_token(tom.payment_gateway_configuration, member, cc_blank)
    end

    answer = member.validate_if_credit_card_already_exist(tom, credit_card_params[:number], credit_card_params[:expire_year], credit_card_params[:expire_month], true, cc_blank, current_agent)
    if answer[:code] == Settings.error_codes.success
      member.enroll(tom, credit_card, enrollment_amount, current_agent, true, cc_blank, member_params, false, false)
    else
      answer
    end
  end

  def enroll(tom, credit_card, amount, agent = nil, recovery_check = true, cc_blank = false, member_params = nil, skip_credit_card_validation = false, skip_product_validation = false)
    allow_cc_blank = (amount.to_f == 0.0 and cc_blank)
    club = tom.club

    unless skip_product_validation
      member_params[:product_sku].to_s.split(',').each do |sku|
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
      trans = Transaction.obtain_transaction_by_gateway!(tom.payment_gateway_configuration.gateway)
      trans.transaction_type = "sale"
      trans.prepare(self, credit_card, amount, tom.payment_gateway_configuration)
      answer = trans.process
      unless trans.success?
        operation_type = Settings.operation_types.error_on_enrollment_billing
        Auditory.audit(agent, trans, "Transaction was not successful.", (self.new_record? ? nil : self), operation_type)
        trans.operation_type = operation_type
        trans.membership_id = nil
        trans.save
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
        trans.membership_id = self.current_membership.id
        trans.last_digits = credit_card.last_digits
        trans.save
        credit_card.accepted_on_billing
      end
      self.reload
      message = set_status_on_enrollment!(agent, trans, amount, enrollment_info)

      response = { :message => message, :code => Settings.error_codes.success, :member_id => self.id, :autologin_url => self.full_autologin_url.to_s, :status => self.status }
      response.merge!(:api_role => tom.api_role.to_s.split(',')) unless self.is_not_drupal?
      response
    rescue Exception => e
      logger.error e.inspect
      error_message = (self.id.nil? ? "Member:enroll" : "Member:recovery/save the sale") + " -- member turned invalid while enrolling"
      Auditory.report_issue(error_message, e, { :member => self.inspect, :credit_card => credit_card.inspect, :enrollment_info => enrollment_info.inspect })
      # TODO: this can happend if in the same time a new member is enrolled that makes this an invalid one. Do we have to revert transaction?
      Auditory.audit(agent, self, error_message, self, Settings.operation_types.error_on_enrollment_billing) 
      { :message => I18n.t('error_messages.member_not_saved', :cs_phone_number => self.club.cs_phone_number), :code => Settings.error_codes.member_not_saved }
    end
  end

  def send_pre_bill
    Communication.deliver!( self.manual_payment ? :manual_payment_prebill : :prebill, self) if membership_billing_enabled?
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
          Auditory.report_issue(answer[:message], answer[:message], { :member => self.inspect, :credit_card => self.active_credit_card.inspect, :enrollment_info => self.current_membership.enrollment_info.inspect })
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

  delegate :is_not_drupal?, :to => :club

  # Resets member club cash in case of a cancelation.
  def nillify_club_cash
    if club.allow_club_cash_transaction?
      add_club_cash(nil, -club_cash_amount, 'Removing club cash because of member cancellation')
      if is_not_drupal?
        self.club_cash_expire_date = nil
        self.save(:validate => false)
      end
    end
  end
  handle_asynchronously :nillify_club_cash, :queue => :generic_queue

  # Resets member club cash in case the club cash has expired.
  def reset_club_cash
    add_club_cash(nil, -club_cash_amount, 'Removing expired club cash.')
    if is_not_drupal?
      self.club_cash_expire_date = self.club_cash_expire_date + 12.months
      self.save(:validate => false)
    end
  end
  handle_asynchronously :reset_club_cash, :queue => :generic_queue

  def assign_first_club_cash 
    assign_club_cash unless terms_of_membership.skip_first_club_cash
  end

  # Adds club cash when membership billing is success. Only on each 12th month, and if it is not the first billing.
  def assign_club_cash(message = "Adding club cash after billing", enroll = false)
    amount = enroll ? terms_of_membership.initial_club_cash_amount : terms_of_membership.club_cash_installment_amount
    self.add_club_cash(nil, amount, message)
    if is_not_drupal?
      if self.club_cash_expire_date.nil? # first club cash assignment
        self.club_cash_expire_date = join_date + 1.year
      end
      self.save(:validate => false)
    end
  rescue Exception => e
    # refs #21133
    # If there is connectivity problems or data errors with drupal. Do not stop billing!! 
    Auditory.report_issue("Member:assign_club_cash:sync", e, { :member => self.inspect, :amount => amount, :message => message })
  end
  handle_asynchronously :assign_club_cash, :queue => :generic_queue, :run_at => Proc.new { 5.minutes.from_now }

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
        elsif is_not_drupal?
          if (amount.to_f < 0 and amount.to_f.abs <= self.club_cash_amount) or amount.to_f > 0
            cct = ClubCashTransaction.new(:amount => amount, :description => description)
            self.club_cash_transactions << cct
            raise "Could not save club cash transaction" unless cct.valid? and self.valid?
            self.club_cash_amount = self.club_cash_amount + amount.to_f
            self.save(:validate => false)
            message = "#{cct.amount.to_f.abs} club cash was successfully #{ amount.to_f >= 0 ? 'added' : 'deducted' }."+(description.blank? ? '' : " Concept: #{description}")
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
        elsif not api_id.nil?
          Drupal::UserPoints.new(self).create!({:amount => amount, :description => description})
          message = last_sync_error || "Club cash processed at drupal correctly."
          auditory_code = Settings.operation_types.remote_club_cash_transaction_failed
          if self.last_sync_error.nil?
            auditory_code = Settings.operation_types.remote_club_cash_transaction
            answer = { :message => message, :code => Settings.error_codes.success }
          else
            answer = { :message => last_sync_error, :code => Settings.error_codes.club_cash_transaction_not_successful }
          end
          answer[:message] = I18n.t('error_messages.drupal_error_sync') if message.blank?
          Auditory.audit(agent, self, answer[:message], self, auditory_code)
        end
      rescue Exception => e
        answer[:errors] = cct.errors_merged(self) unless cct.nil?
        Auditory.report_issue('Club cash Transaction', e.to_s + answer[:message], { :member => self.inspect, :amount => amount, :description => description, :club_cash_transaction => (cct.inspect unless cct.nil?) })
        answer[:message] = I18n.t('error_messages.airbrake_error_message')
        raise ActiveRecord::Rollback
      end
    end
    answer
  end

  # Bug #27501 this method was added just to be used from console.
  def unblacklist(agent = nil)
    if self.blacklisted?
      Member.transaction do
        begin
          self.blacklisted = false
          self.save(:validate => false)
          Auditory.audit(agent, self, "Un-blacklisted member and all its credit cards.", self, Settings.operation_types.unblacklisted)
          self.credit_cards.each { |cc| cc.unblacklist }
          marketing_tool_sync_subscription
        rescue Exception => e
          Auditory.report_issue("Member::unblacklist", e, { :member => self.inspect })
          raise ActiveRecord::Rollback
        end
      end
    end
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
            self.cancel! Time.zone.now.in_time_zone(get_club_timezone), "Automatic cancellation"
            self.set_as_canceled!
          end
          marketing_tool_sync_unsubscription  
          answer = { :message => message, :code => Settings.error_codes.success }
        rescue Exception => e
          Auditory.report_issue("Member::blacklist", e, { :member => self.inspect })
          answer = { :message => I18n.t('error_messages.airbrake_error_message')+e.to_s, :success => Settings.error_codes.member_could_no_be_blacklisted }
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
      :member_group_type_id, :preferences, :external_id, :manual_payment ].each do |key|
          self.send("#{key}=", params[key]) if params.include? key
    end
    self.type_of_phone_number = params[:type_of_phone_number].to_s.downcase if params.include? :type_of_phone_number
  end

  def chargeback!(transaction_chargebacked, args)
    trans = Transaction.obtain_transaction_by_gateway!(transaction_chargebacked.gateway)
    trans.new_chargeback(transaction_chargebacked, args)
    self.blacklist nil, "Chargeback - "+args[:reason]
  end

  def cancel!(cancel_date, message, current_agent = nil, operation_type = Settings.operation_types.future_cancel)
    cancel_date = cancel_date.to_date
    cancel_date = (self.join_date.in_time_zone(get_club_timezone).to_date == cancel_date ? "#{cancel_date} 23:59:59" : cancel_date).to_datetime
    if not message.blank?
      if cancel_date.change(:offset => self.get_offset_related).to_date >= Time.new.getlocal(self.get_offset_related).to_date
        if self.cancel_date == cancel_date
          answer = { :message => "Cancel date is already set to that date", :code => Settings.error_codes.wrong_data }
        else
          if can_be_canceled?
            self.current_membership.update_attribute :cancel_date, cancel_date.to_datetime.change(:offset => self.get_offset_related )
            answer = { :message => "Member cancellation scheduled to #{cancel_date.to_date} - Reason: #{message}", :code => Settings.error_codes.success }
            Auditory.audit(current_agent, self, answer[:message], self, operation_type)
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

  # Method used from rake task and also from tests!
  def self.bill_all_members_up_today
    file = File.open("/tmp/bill_all_members_up_today_#{Rails.env}.lock", File::RDWR|File::CREAT, 0644)
    file.flock(File::LOCK_EX)

    base = Member.includes(:current_membership => :terms_of_membership).where("DATE(next_retry_bill_date) <= ? AND members.club_id IN (select id from clubs where billing_enable = true) AND members.status NOT IN ('applied','lapsed') AND manual_payment = false AND terms_of_memberships.is_payment_expected = 1", Time.zone.now.to_date).limit(2000)

    Rails.logger.info " *** [#{I18n.l(Time.zone.now, :format =>:dashed)}] Starting members:billing rake task, processing #{base.count} members"
    base.to_enum.with_index.each do |member,index| 
      tz = Time.zone.now
      begin
        Rails.logger.info "  *[#{index+1}] processing member ##{member.id} nbd: #{member.next_retry_bill_date}"
        member.bill_membership
      rescue Exception => e
        Auditory.report_issue("Billing::Today", "#{e.to_s}\n\n#{$@[0..9] * "\n\t"}", { :member => member.inspect, :credit_card => member.active_credit_card.inspect })
        Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
      end
      Rails.logger.info "    ... took #{Time.zone.now - tz} for member ##{member.id}"
    end
    file.flock(File::LOCK_UN)
  rescue Exception => e
    Auditory.report_issue("Billing::Today", e, {:backtrace => "#{$@[0..9] * "\n\t"}"})
    Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
  end

  def self.refresh_autologin
    index = 0
    Member.find_each do |member|
      begin
        index = index+1
        Rails.logger.info "   *[#{index}] processing member ##{member.id}"
        member.refresh_autologin_url!
      rescue
        Auditory.report_issue("Members::Members", "#{e.to_s}\n\n#{$@[0..9] * "\n\t"}", { :member => member.inspect })
        Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
      end
    end
  end

  def self.send_pillar_emails 
    base = ActiveRecord::Base.connection.execute("SELECT memberships.member_id,email_templates.id FROM memberships INNER JOIN terms_of_memberships ON terms_of_memberships.id = memberships.terms_of_membership_id INNER JOIN email_templates ON email_templates.terms_of_membership_id = terms_of_memberships.id WHERE (email_templates.template_type = 'pillar' AND date(join_date) = DATE_SUB(CURRENT_DATE(), INTERVAL email_templates.days_after_join_date DAY) AND status IN ('active','provisional'))")
    Rails.logger.info " *** [#{I18n.l(Time.zone.now, :format =>:dashed)}] Starting members:send_pillar_emails rake task, processing #{base.count} templates"
    base.to_enum.with_index.each do |res,index|
      begin
        tz = Time.zone.now
        member = Member.find res[0]
        template = EmailTemplate.find res[1]
        Rails.logger.info "   *[#{index+1}] processing member ##{member.id}"
        Communication.deliver!(template, member)
        Rails.logger.info "    ... took #{Time.zone.now - tz} for member ##{member.id}"
      rescue Exception => e
        Auditory.report_issue("Members::SendPillar", "#{e.to_s}\n\n#{$@[0..9] * "\n\t"}", { :template => template.inspect, :membership => member.current_membership.inspect })
        Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
      end
    end
  rescue Exception => e
    Auditory.report_issue("Members::SendPillar", e, {:backtrace => "#{$@[0..9] * "\n\t"}"})
    Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
  end

  # Method used from rake task and also from tests!
  def self.reset_club_cash_up_today
    base = Member.includes(:club).where("date(club_cash_expire_date) <= ? AND clubs.api_type != 'Drupal::Member' AND club_cash_enable = true", Time.zone.now.to_date).limit(2000)
    Rails.logger.info " *** [#{I18n.l(Time.zone.now, :format =>:dashed)}] Starting members:reset_club_cash_up_today rake task, processing #{base.count} members"
    base.to_enum.with_index.each do |member,index|
      tz = Time.zone.now
      begin
        Rails.logger.info "  *[#{index+1}] processing member ##{member.id}"
        member.reset_club_cash
      rescue Exception => e
        Auditory.report_issue("Member::ClubCash", "#{e.to_s}\n\n#{$@[0..9] * "\n\t"}", { :member => member.inspect })
        Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
      end
      Rails.logger.info "    ... took #{Time.zone.now - tz} for member ##{member.id}"
    end
  rescue Exception => e
    Auditory.report_issue("Members::ClubCash", e, {:backtrace => "#{$@[0..9] * "\n\t"}"})
    Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
  end

  # Method used from rake task and also from tests!
  def self.cancel_all_member_up_today
    base =  Member.includes(:current_membership).where("date(memberships.cancel_date) <= ? AND memberships.status != ? ", Time.zone.now.to_date, 'lapsed')
    base_for_manual_payment = Member.includes(:current_membership).where("manual_payment = true AND date(bill_date) < ? AND memberships.status != ?", Time.zone.now.to_date, 'lapsed')
   
    [base, base_for_manual_payment].each do |list|
      Rails.logger.info " *** [#{I18n.l(Time.zone.now, :format =>:dashed)}] Starting members:cancel_all_member_up_today rake task, processing #{base.count} members"
      list.each_with_index do |member, index| 
        tz = Time.zone.now
        begin
          Rails.logger.info "  *[#{index+1}] processing member ##{member.id}"
          member.cancel!(Time.zone.now.in_time_zone(member.get_club_timezone), "Billing date is overdue.", nil, Settings.operation_types.bill_overdue_cancel) if member.manual_payment and not member.cancel_date
          member.set_as_canceled!
        rescue Exception => e
          Auditory.report_issue("Members::Cancel", "#{e.to_s}\n\n#{$@[0..9] * "\n\t"}", { :member => member.inspect })
          Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
        end
        Rails.logger.info "    ... took #{Time.zone.now - tz} for member ##{member.id}"
      end
    end
  rescue Exception => e
    Auditory.report_issue("Members::Cancel", e, {:backtrace => "#{$@[0..9] * "\n\t"}"})
    Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
  end

  def self.process_sync 
    base = Member.where('status = "lapsed" AND api_id != "" and ( last_sync_error not like "There is no user with ID%" or last_sync_error is NULL )')
    tz = Time.zone.now
    Rails.logger.info " *** [#{I18n.l(Time.zone.now, :format =>:dashed)}] Starting members:process_sync rake task with members lapsed and api_id not null, processing #{base.count} members"
    base.find_in_batches do |group|
      group.each do |member|
        begin
          api_m = member.api_member
          unless api_m.nil?
            api_m.destroy!
            Auditory.audit(nil, member, "Member's drupal account destroyed by batch script", member, Settings.operation_types.member_drupal_account_destroyed_batch)
          end
        rescue Exception => e
          Auditory.report_issue("Members::Sync", e, {:member => member.inspect})
          Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
        end
      end
    end
    Rails.logger.info "    ... took #{Time.zone.now - tz}"

    base = Member.where('last_sync_error like "There is no user with ID%"')
    base2 = Member.where('status = "lapsed" and last_sync_error like "%The e-mail address%is already taken%"')
    Rails.logger.info " *** [#{I18n.l(Time.zone.now, :format =>:dashed)}] Starting members:process_sync rake task with members with error sync related to wrong api_id, processing #{base.count+base2.count} members"
    tz = Time.zone.now
    index = 0
    [base,base2].each do |group|
      group.each do |member|
        begin
          Rails.logger.info "  *[#{index+1}] processing member ##{member.id}"
          member.api_id = nil 
          member.last_sync_error = nil
          member.last_sync_error_at = nil
          member.last_synced_at = nil
          member.sync_status = "not_synced"
          member.save(:validate => false)
          unless member.lapsed?
            api_m = member.api_member
            unless api_m.nil?
              if api_m.save!(force: true)
                unless member.last_sync_error_at
                  Auditory.audit(nil, member, "Member synchronized by batch script", member, Settings.operation_types.member_drupal_account_synced_batch)
                end
              end
            end
          end
          index = index + 1
        rescue Exception => e
          Auditory.report_issue("Members::Sync", e, {:member => member.inspect})
          Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
        end
      end
    end
    Rails.logger.info "    ... took #{Time.zone.now - tz}"

    base = Member.joins(:club).where("sync_status IN ('with_error', 'not_synced') AND status != 'lapsed' AND clubs.api_type != '' ").limit(2000)
    Rails.logger.info " *** [#{I18n.l(Time.zone.now, :format =>:dashed)}] Starting members:process_sync rake task with members not_synced or with_error, processing #{base.count} members"
    tz = Time.zone.now
    base.to_enum.with_index.each do |member,index|
      begin
        Rails.logger.info "  *[#{index+1}] processing member ##{member.id}"
        api_m = member.api_member
        unless api_m.nil?
          if api_m.save!(force: true)
            unless member.last_sync_error_at
              Auditory.audit(nil, member, "Member synchronized by batch script", member, Settings.operation_types.member_drupal_account_synced_batch)
            end
          end
        end
      rescue Exception => e
        Auditory.report_issue("Members::Sync", e, {:member => member.inspect})
        Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
      end
    end       
    Rails.logger.info "    ... took #{Time.zone.now - tz}"

  rescue Exception => e
    Auditory.report_issue("Members::Sync", e, {:backtrace => "#{$@[0..9] * "\n\t"}"})
    Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
  end

  def self.process_email_sync_error
    member_list = {}
    base = Member.where("sync_status = 'with_error' AND last_sync_error like '%The e-mail address%is already taken%'")
    Rails.logger.info " *** [#{I18n.l(Time.zone.now, :format =>:dashed)}] Starting members:process_email_sync_error rake task, processing #{base.count} members"
    base.find_in_batches do |group|
      group.each_with_index do |member, index|
        club = member.club
        row = "ID: #{member.id} - Partner-Club: #{club.partner.name}-#{club.name} - Email: #{member.email} - Status: #{member.status} - Drupal domain link: #{member.club.api_domain.url}/admin/people}"
        member_list.merge!("member#{index+1}" => row)
      end
    end
    Auditory.report_issue("Members::DuplicatedEmailSyncError.", "The following members are having problems with the syncronization due to duplicated emails.", member_list, false) unless member_list.empty?
  rescue Exception => e
    Auditory.report_issue("Members::SyncErrorEmail", e, {:backtrace => "#{$@[0..9] * "\n\t"}"})
    Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"  
  end

  def self.send_happy_birthday
    today = Time.zone.now.to_date
    base = Member.billable.where(" birth_date IS NOT NULL and DAYOFMONTH(birth_date) = ? and MONTH(birth_date) = ? ", 
      today.day, today.month)
    Rails.logger.info " *** [#{I18n.l(Time.zone.now, :format =>:dashed)}] Starting members:send_happy_birthday rake task, processing #{base.count} members"
    base.find_in_batches do |group|
      group.to_enum.with_index.each do |member,index| 
        tz = Time.zone.now
        begin
          Rails.logger.info "  *[#{index+1}] processing member ##{member.id}"
          Communication.deliver!(:birthday, member)
        rescue Exception => e
          Auditory.report_issue("Members::sendHappyBirthday", "#{e.to_s}\n\n#{$@[0..9] * "\n\t"}", { :member => member.inspect })
          Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
        end
        Rails.logger.info "    ... took #{Time.zone.now - tz} for member ##{member.id}"
      end
    end
  rescue Exception => e
    Auditory.report_issue("Members::sendHappyBirthday", e, {:backtrace => "#{$@[0..9] * "\n\t"}"})
    Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
  end

  def self.send_prebill
    base = Member.joins(:current_membership => :terms_of_membership).where(
                          ["((date(next_retry_bill_date) = ? AND recycled_times = 0) 
                           OR (date(next_retry_bill_date) = ? AND manual_payment = true)) 
                           AND terms_of_memberships.installment_amount != 0.0 
                           AND terms_of_memberships.is_payment_expected = true", 
                           (Time.zone.now + 7.days).to_date, (Time.zone.now + 14.days).to_date 
                          ])

    base.find_in_batches do |group|
      group.each_with_index do |member,index| 
        tz = Time.zone.now
        begin
          Rails.logger.info "  *[#{index+1}] processing member ##{member.id}"
          member.send_pre_bill
        rescue Exception => e
          Auditory.report_issue("Billing::SendPrebill", "#{e.to_s}\n\n#{$@[0..9] * "\n\t"}", { :member => member.inspect })
          Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
        end
        Rails.logger.info "    ... took #{Time.zone.now - tz} for member ##{member.id}"
      end
    end
  rescue Exception => e
    Auditory.report_issue("Members::SendPrebill", e, {:backtrace => "#{$@[0..9] * "\n\t"}"})
    Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
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
    new_credit_card.get_token(tom.payment_gateway_configuration, self)
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
            Auditory.report_issue("Members::update_credit_card_from_drupal", "#{e.to_s}\n\n#{$@[0..9] * "\n\t"}", { :new_active_credit_card => new_active_credit_card.inspect, :member => self.inspect })
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
        new_credit_card.gateway = self.terms_of_membership.payment_gateway_configuration.gateway if new_credit_card.gateway.nil?
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
        Auditory.report_issue("Member:update_credit_card", e, { :member => self.inspect, :credit_card => new_credit_card.inspect })
        raise ActiveRecord::Rollback
      end
    end
    answer
  end

  def desnormalize_additional_data
    if self.additional_data.present?
      self.additional_data.each do |key, value|
        pref = MemberAdditionalData.find_or_create_by_member_id_and_club_id_and_param(self.id, self.club_id, key)
        pref.value = value
        pref.save
      end
    end
  end
  handle_asynchronously :desnormalize_additional_data, :queue => :generic_queue

  def desnormalize_preferences
    if self.preferences.present?
      self.preferences.each do |key, value|
        pref = MemberPreference.find_or_create_by_member_id_and_club_id_and_param(self.id, self.club_id, key)
        pref.value = value
        pref.save
      end
    end
  end
  handle_asynchronously :desnormalize_preferences, :queue => :generic_queue

  def marketing_tool_sync
    self.exact_target_after_create_sync_to_remote_domain if defined?(SacExactTarget::MemberModel)
  end
  handle_asynchronously :marketing_tool_sync, :queue => :exact_target_sync

  # used for member blacklist
  def marketing_tool_sync_unsubscription
    if defined?(SacExactTarget::MemberModel) and not exact_target_member.nil?
      exact_target_after_create_sync_to_remote_domain
      exact_target_member.unsubscribe!
    end
  rescue Exception => e
    logger.error "* * * * * #{e}"
    Auditory.report_issue("Member::unsubscribe", e, { :member => self.inspect })
  end
  handle_asynchronously :marketing_tool_sync_unsubscription, :queue => :exact_target_sync

  # used for member unblacklist
  def marketing_tool_sync_subscription
    exact_target_member.subscribe! if defined?(SacExactTarget::MemberModel)
  end
  handle_asynchronously :marketing_tool_sync_subscription, :queue => :exact_target_sync

  def get_offset_related
    Time.now.in_time_zone(get_club_timezone).formatted_offset
  end

  def get_club_timezone
    @club_timezone ||= self.club.time_zone
  end

  private
    def schedule_renewal(manual = false)
      new_bill_date = Time.zone.now + terms_of_membership.installment_period.days
      # refs #15935
      self.recycled_times = 0
      self.bill_date = new_bill_date
      self.next_retry_bill_date = new_bill_date
      self.save(:validate => false)
      Auditory.audit(nil, self, "Renewal scheduled. NBD set #{new_bill_date.to_date}", self, Settings.operation_types.renewal_scheduled)
    end

    def check_upgradable
      if terms_of_membership.upgradable?
        if join_date.to_date + terms_of_membership.upgrade_tom_period.days <=  Time.new.getlocal(self.get_offset_related).to_date
          change_terms_of_membership(terms_of_membership.upgrade_tom_id, "Upgrade member from TOM(#{self.terms_of_membership_id}) to TOM(#{terms_of_membership.upgrade_tom_id})", Settings.operation_types.tom_upgrade)
          return false
        end
      end
      true
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
      Auditory.audit(agent, (trans.nil? ? terms_of_membership : trans), message, self, operation_type)
      trans.update_attribute :operation_type, operation_type unless trans.nil?
      message
    end

    def proceed_with_manual_billing_logic(trans, operation_type)
      unless set_as_active
        Auditory.report_issue("Billing:manual_billing::set_as_active", "we cant set as active this member.", { :member => self.inspect, :membership => current_membership.inspect, :trans => trans.inspect })
      end
      message = "Member manually billed successfully $#{trans.amount} Transaction id: #{trans.id}"
      Auditory.audit(nil, trans, message, self, operation_type)
      if check_upgradable 
        schedule_renewal(true)
      end
      { :message => message, :code => Settings.error_codes.success, :member_id => self.id }
    end

    def proceed_with_billing_logic(trans)
      unless set_as_active
        Auditory.report_issue("Billing::set_as_active", "we cant set as active this member.", { :member => self.inspect, :membership => current_membership.inspect, :trans => trans.inspect })
      end
      if check_upgradable 
        schedule_renewal
      end
      message = "Member billed successfully $#{trans.amount} Transaction id: #{trans.id}"
      Auditory.audit(nil, trans, message, self, Settings.operation_types.membership_billing)
      { :message => message, :code => Settings.error_codes.success, :member_id => self.id }
    end

    def fulfillments_products_to_send
      self.current_membership.enrollment_info.product_sku ? self.current_membership.enrollment_info.product_sku.split(',') : []
    end

    def record_date
      self.member_since_date = Time.zone.now
    end

    def cancellation
      self.cancel_member_at_remote_domain
      if (Time.zone.now.to_date - join_date.to_date).to_i <= Settings.days_to_wait_to_cancel_fulfillments
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
      tom = terms_of_membership
      decline = DeclineStrategy.find_by_gateway_and_response_code_and_credit_card_type(trans.gateway.downcase, 
                  trans.response_code, trans.cc_type) || 
                DeclineStrategy.find_by_gateway_and_response_code_and_credit_card_type(trans.gateway.downcase, 
                  trans.response_code, "all")
      cancel_member = false

      if decline.nil?
        # we must send an email notifying about this error. Then schedule this job to run in the future (1 month)
        message = "Billing error. No decline rule configured: #{trans.response_code} #{trans.gateway}: #{trans.response_result}"
        operation_type = Settings.operation_types.membership_billing_without_decline_strategy
        self.next_retry_bill_date = Time.zone.now + eval(Settings.next_retry_on_missing_decline)
        self.save(:validate => false)
        Auditory.report_issue("Decline rule not found TOM ##{tom.id}", 
          "MID ##{self.id} TID ##{trans.id}. Message: #{message}. CC type: #{trans.cc_type}. " + 
          "We have scheduled this billing to run again in #{Settings.next_retry_on_missing_decline} days.",
          { :member => self.inspect })
        if self.recycled_times < Settings.number_of_retries_on_missing_decline
          Auditory.audit(nil, trans, message, self, operation_type)
          trans.update_attribute :operation_type, operation_type
          increment!(:recycled_times, 1)
          return message
        end
        message = "Billing error. No decline rule configured limit reached: #{trans.response_code} #{trans.gateway}: #{trans.response_result}"
        operation_type = Settings.operation_types.membership_billing_without_decline_strategy_max_retries
        cancel_member = true
      else
        trans.decline_strategy_id = decline.id
        if decline.hard_decline?
          message = "Hard Declined: #{trans.response_code} #{trans.gateway}: #{trans.response_result}"
          operation_type = (tom.downgradable? ? Settings.operation_types.downgraded_because_of_hard_decline : Settings.operation_types.membership_billing_hard_decline)
          cancel_member = true
        else
          message="Soft Declined: #{trans.response_code} #{trans.gateway}: #{trans.response_result}"
          self.next_retry_bill_date = decline.days.days.from_now
          operation_type = Settings.operation_types.membership_billing_soft_decline
          if self.recycled_times > (decline.max_retries-1)
            message = "Soft recycle limit (#{self.recycled_times}) reached: #{trans.response_code} #{trans.gateway}: #{trans.response_result}"
            operation_type = (tom.downgradable? ? Settings.operation_types.downgraded_because_of_hard_decline_by_max_retries : Settings.operation_types.membership_billing_hard_decline_by_max_retries)
            cancel_member = true
          end
        end
      end
      self.save(:validate => false)
      Auditory.audit(nil, trans, message, self, operation_type )
      if cancel_member
        if tom.downgradable?
          downgrade_member
        else
          self.cancel! Time.zone.now.in_time_zone(get_club_timezone), "HD cancellation"
          set_as_canceled!
          Communication.deliver!(:hard_decline, self)    
        end
      else
        increment!(:recycled_times, 1)
        Communication.deliver!(:soft_decline, self)
      end
      trans.operation_type = operation_type
      trans.save
      message
    end

    def asyn_desnormalize_preferences(opts = {})
      self.desnormalize_preferences if opts[:force] || self.changed.include?('preferences') 
      self.desnormalize_additional_data if opts[:force] || self.changed.include?('additional_data') 
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

    def after_marketing_tool_sync
      marketing_tool_sync
    end
end
