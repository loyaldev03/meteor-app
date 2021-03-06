# encoding: utf-8
class User < ActiveRecord::Base
  extend Extensions::User::CountrySpecificValidations
#  extend Extensions::Member::DateSpecificValidations
  extend FriendlyId
  friendly_id :slug_candidate, use: :slugged

  belongs_to :club
  belongs_to :member_group_type
  has_many :user_notes
  has_many :credit_cards
  has_many :transactions, ->{ order("created_at ASC") }
  has_many :operations
  has_many :communications, ->{ order("created_at DESC") }
  has_many :fulfillments
  has_many :club_cash_transactions
  has_many :user_preferences
  has_many :user_additional_data
  has_many :memberships, ->{ order("created_at DESC") }
  belongs_to :current_membership, class_name: 'Membership'
  
  # TODO: should we use delegate??
  delegate :terms_of_membership, to: :current_membership
  # attr :terms_of_membership_id # is it necesarilly??? 
  delegate :terms_of_membership_id, to: :current_membership
  delegate :join_date, to: :current_membership
  delegate :cancel_date, to: :current_membership
  delegate :time_zone, to: :club
  ##### 
  
  serialize :preferences, JSON
  serialize :additional_data, JSON
  serialize :change_tom_attributes, JSON

  before_create :record_date
  before_save :wrong_address_logic
  before_save :set_marketing_client_sync_as_needed
  before_save :apply_downcase_to_email
  before_save :prepend_zeros_to_phone_number
  before_update :check_if_vip_member_allowed
  after_create :elasticsearch_asyn_call
  after_create 'asyn_desnormalize_preferences(force: true)'
  after_save :create_operation_on_testing_account_toggle
  after_update :elasticsearch_asyn_call
  after_update :mkt_tool_check_email_changed_for_sync
  after_update :after_save_sync_to_remote_domain
  after_update :asyn_desnormalize_preferences
  after_update :update_club_cash_if_vip_member
  after_destroy :cancel_user_at_remote_domain

  # skip_api_sync wont be use to prevent remote destroy. will be used to prevent creates/updates
  def cancel_user_at_remote_domain
    if is_cms_configured?
      if is_drupal?
        Users::CancelUserRemoteDomainJob.perform_later(user_id: id)
      elsif is_spree?
        Users::SyncToRemoteDomainJob.perform_later(user_id: id)
      end
    end
  end

  def after_save_sync_to_remote_domain
    if is_cms_configured?
      if is_drupal?
        Users::SyncToRemoteDomainJob.perform_now(user_id: id) if defined?(Drupal::Member) && (Drupal::Member::OBSERVED_FIELDS.intersection(changed).any? && (!@skip_api_sync || api_user.nil?)) # change tracker
      elsif is_spree? && defined?(Spree::Member) && !@skip_api_sync
        if api_id.nil? || Spree::Member::OBSERVED_FIELDS.intersection(changed).any?
          Users::SyncToRemoteDomainJob.perform_now(user_id: id)
        end
      end
    end
  end

  validates :country,
    presence:                    true, 
    length:                      { is: 2, allow_nil: true },
    inclusion:                   { within: self.supported_countries }
  country_specific_validations!
  validates :birth_date, birth_date: true
  validates :email, email: true

  scope :billable, lambda { where('status IN (?, ?)', 'provisional', 'active') }
  scope :with_billing_enable, lambda { joins(:club).where('billing_enable = true') }

  ########### SEARCH ###############
  include Tire::Model::Search
  index_name "users_#{Rails.env}"
  settings analysis: {
    filter: {
      email_filter: {
         type: "pattern_capture",
         preserve_original: 1,
         patterns: [
            "(\\w+)",
            "(\\p{L}+)",
            "(\\d+)",
            "@(.+)",
            "@(\\w+)"
         ]
      },
      transaction_filter: {
        type: 'pattern_capture',
        patterns: [
          "[0-9\-]{10}:[0-9\.]{5}",
          "[0-9\-]{10}:",
          ":[0-9\.]{5}"
        ]
      }
    },
    tokenizer: {
      transaction_tokenizer: {
        type: "pattern",
        pattern: ","
      }
    },
    analyzer: {
      email_analyzer: {
        type: 'custom',
        tokenizer: 'uax_url_email',
        filter: ['email_filter', 'lowercase', 'asciifolding']
      },
      transaction_analyzer: {
        type: 'custom',
        tokenizer: 'transaction_tokenizer',
        filter: ['transaction_filter']
      }
    }
  } do
      mapping do
        indexes :id,                type: "long", index: :not_analyzed
        indexes :first_name,        type: "string",  analyzer: 'standard'
        indexes :last_name,         type: "string",  analyzer: 'standard'
        indexes :full_name,         type: "string",  analyzer: 'standard'
        indexes :city,              type: "string",  analyzer: 'standard'
        indexes :zip,               type: "string",  analyzer: 'keyword'
        indexes :email,             type: "string",  analyzer: 'email_analyzer'
        indexes :country,           type: "string",  analyzer: 'standard'
        indexes :state,             type: "string",  analyzer: 'standard'
        indexes :full_address,      type: "string",  analyzer: 'standard'
        indexes :cc_last_digits,    type: "string",  analyzer: 'standard'
        indexes :status,            type: "string",  analyzer: 'standard'
        indexes :phone_number,      type: "string",  analyzer: 'standard'
        indexes :transaction_info,  type: "string", analyzer: 'transaction_analyzer'
        indexes :club_id,           type: "long", analyzer: 'standard'
      end
  end



  def to_indexed_json
    {id: id,
    first_name: first_name,
    last_name: last_name,
    full_name: full_name,
    city: city,
    zip: zip,
    email: email,
    country: country,
    full_address: full_address,
    state: state,
    status: status,
    cc_last_digits: active_credit_card.last_digits, 
    phone_number: full_phone_number.gsub(/\D/, ''),
    transaction_info: transactions.collect{|t| "#{t.created_at.to_date.to_s}:#{sprintf('%.2f', t.amount)}"}.join(','),
    club_id: club_id,
    }.to_json
  end
  # Async indexing
  def async_elasticsearch_index
    Users::AsyncElasticSearchIndexJob.perform_later(self.id)
  end

  def elasticsearch_asyn_call
    async_elasticsearch_index if not (self.changed & ['id', 'first_name', 'last_name', 'zip', 'city', 'country', 'state', 'address', 'email', 'status', 'phone_country_code', 'phone_area_code', 'phone_local_number']).empty?
  end
  ########### SEARCH ###############

  state_machine :status, initial: :none, action: :save_state do
    ###### member gets applied =====>>>>
    after_transition lapsed:                         :applied, do: [:set_join_date, :send_recover_needs_approval_email]
    after_transition [ :none, :provisional, :active ] => # none is new join. provisional and active are save the sale
                        :applied, :do => [:set_join_date, :send_active_needs_approval_email]
    ###### <<<<<<========
    ###### member gets provisional =====>>>>
    after_transition [ :none, :lapsed ] => # enroll and reactivation
                        :provisional, :do => ['schedule_first_membership(true, false, false, false)','after_marketing_tool_sync']
    after_transition [ :provisional, :active ] => 
                        :provisional, :do => 'schedule_first_membership(true, true, true, true)' # save the sale
    after_transition applied:                         :provisional, do: 'schedule_first_membership(false)'
    ###### <<<<<<========
    ###### Cancellation =====>>>>
    after_transition [:provisional, :active ] => 
                        :lapsed, :do => [:cancellation, :nillify_club_cash_upon_cancellation]
    after_transition applied:                         :lapsed, do: [:set_user_as_rejected, :send_rejection_communication]
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
    save(validate: false)
  end

  # Sends the request mail to every representative to accept/reject the member.
  def send_active_needs_approval_email
    Users::SendNeedsApprovalEmailJob.perform_later(user_id: self.id, active: true)
  end
  # Sends the request mail to every representative to accept/reject the member.
  def send_recover_needs_approval_email
    Users::SendNeedsApprovalEmailJob.perform_later(user_id: self.id, active: false)
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

  def set_user_as_rejected
    self.current_membership.update_attribute(:cancel_date, Time.zone.now)
  end

  def send_rejection_communication
    Communication.deliver!(:rejection, self)
  end

  # Sends the fulfillment, and it settes bill_date and next_retry_bill_date according to member's terms of membership.
  def schedule_first_membership(set_join_date, skip_send_fulfillment = false, skip_nbd_and_current_join_date_update_for_sts = false, skip_add_club_cash = false)
    membership = current_membership
    if set_join_date
      membership.update_attribute :join_date, Time.zone.now
    end

    Users::PostEnrollmentTasks.perform_later(id, skip_send_fulfillment)

    if not skip_nbd_and_current_join_date_update_for_sts and is_billing_expected?
      self.bill_date = membership.join_date + terms_of_membership.provisional_days.days
      self.next_retry_bill_date = membership.join_date + terms_of_membership.provisional_days.days
      self.current_join_date = Time.zone.now
    end
    self.recycled_times = 0
    self.change_tom_date = nil
    self.change_tom_attributes = nil
    self.save(validate: false)
    assign_club_cash('club cash on enroll', true) unless skip_add_club_cash
  end

  # Changes next bill date.
  def change_next_bill_date(next_bill_date, current_agent = nil, concept = "")
    if not  is_billing_expected?
      errors = { member: 'is not expected to get billed.' }
      answer = { message: I18n.t('error_messages.not_expecting_billing'), code: Settings.error_codes.user_not_expecting_billing, errors: errors }
    elsif not self.can_change_next_bill_date?
      errors = { member: 'is not in billable status' }
      answer = { message: I18n.t('error_messages.unable_to_perform_due_user_status'), code: Settings.error_codes.next_bill_date_blank, errors: errors }
    elsif next_bill_date.blank?
      errors = { next_bill_date: 'is blank' }
      answer = { message: I18n.t('error_messages.next_bill_date_blank'), code: Settings.error_codes.next_bill_date_blank, errors: errors }
    elsif next_bill_date.to_date < Time.zone.now.in_time_zone(self.club.time_zone).to_date
      errors = { next_bill_date: 'Is prior to actual date' }
      answer = { message: "Next bill date should be older that actual date.", code: Settings.error_codes.next_bill_date_prior_actual_date, errors: errors }
    elsif self.valid? and not self.active_credit_card.expired?
      next_bill_date = next_bill_date.to_datetime.change(offset: self.get_offset_related(next_bill_date.to_date))
      self.next_retry_bill_date = next_bill_date
      self.bill_date = next_bill_date
      self.recycled_times = 0
      self.save(validate: false)
      message = "Next bill date changed to #{next_bill_date.to_date} #{concept.to_s}"
      Auditory.audit(current_agent, self, message, self, Settings.operation_types.change_next_bill_date)
      answer = {message: message, code: Settings.error_codes.success }
    else
      errors = self.errors.to_hash
      errors = errors.merge!({credit_card: "is expired"}) if self.active_credit_card.expired?
      answer = { errors: errors, code: Settings.error_codes.user_data_invalid }
    end
    answer
  rescue ArgumentError => e
    return { message: "Next bill date wrong format.", errors: { next_bill_date: "invalid date"}, code: Settings.error_codes.wrong_data } 
  rescue Exception => e
    Auditory.report_issue("User:change_next_bill_date", e, { user: self.id })
    return { message: I18n.t('error_messages.airbrake_error_message'), code: Settings.error_codes.could_not_change_next_bill_date }
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
    self.credit_cards.find_by(active: true)
  end

  # Returns a string with address, city and state concatenated. 
  def full_address
    [address, city, state].join(' ')
  end

  def full_phone_number
    "+#{self.phone_country_code} (#{self.phone_area_code}) #{self.phone_local_number}"
  end

  def payment_gateway_configuration
    @payment_gateway_configuration ||= active_credit_card.payment_gateway_configuration
  end

  ####  METHODS USED TO SHOW OR NOT BUTTONS. 

  def can_be_synced_to_remote?
    if is_drupal?
      !(lapsed? or applied?) and club.billing_enable
    elsif is_spree?
      !(applied?) and club.billing_enable
    end
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
    api_user && !lapsed?
  end

  # Returns true if member is lapsed or if it didnt reach the max reactivation times.
  def can_recover?
    self.lapsed? and not self.blacklisted
  end

  def is_chargeback?
    self.operations.each do |operation|
      return true if operation.operation_type == 110
    end
    false
  end

  def can_be_chargeback?
    club.billing_enable
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

  def can_be_unblacklisted?
    blacklisted?
  end

  def can_add_club_cash?
    if !is_drupal?
      return true
    elsif self.api_id.present?
      return true
    end
    false
  end

  def can_change_next_bill_date?
    not self.applied? and not self.lapsed?
  end

  def has_been_sd_cc_expired?
    transactions.where('membership_id = ? AND transaction_type = "sale" AND success = false', current_membership_id).reorder('created_at DESC').limit(recycled_times).each do |transaction|
      return true if transaction.is_response_code_cc_expired?
    end
    false
  end

  def can_update_vip_member_status?
    @tom_freemium ||= terms_of_membership.freemium?
    (!@tom_freemium || vip_member?) && (!lapsed? || vip_member?)
  end

  def vip_member?
    member_group_type_id ? (member_group_type.name == 'VIP') : false
  end

  ###############################################

  def change_terms_of_membership(tom, operation_message, operation_type, agent = nil, prorated = false, credit_card_params = nil, membership_params = nil, schedule_date = nil, additional_actions = {})
    agent = agent || Agent.find_by(email: Settings.batch_agent_email)
    if can_change_tom?
      new_tom = tom.kind_of?(TermsOfMembership) ? tom : TermsOfMembership.find_by(id: tom)
      if new_tom
        if new_tom.club_id == self.club_id
          if new_tom.id == terms_of_membership.id
            response = { message: "Nothing to change. Member is already enrolled on that TOM.", code: Settings.error_codes.nothing_to_change_tom }
          else
            previous_membership = current_membership
            if schedule_date
              self.change_tom_date = schedule_date
              self.change_tom_attributes = additional_actions.merge(terms_of_membership_id: tom.id)
              self.change_tom_attributes.merge!(agent_id: agent.id)
              self.save(validate: false)
              Auditory.audit(agent, self, operation_message, self, operation_type)
              return { message: operation_message, code: Settings.error_codes.success }
            end

            response = if prorated
              prorated_enroll(new_tom, agent, credit_card_params, membership_params)
            else
              enroll(new_tom, self.active_credit_card, 0.0, agent, false, 0, membership_params, true, true, true)
            end

            if response[:code] == Settings.error_codes.success
              Auditory.audit(agent, new_tom, operation_message, self, operation_type)
              Membership.find_by(id: previous_membership.id).cancel_because_of_membership_change
              self.current_membership.update_attribute :parent_membership_id, previous_membership.id
            # update manually this fields because we cant cancel member
            end
          end
          response
        else
          { message: "Tom(#{new_tom.id}) to change belongs to another club.", code: Settings.error_codes.tom_to_downgrade_belongs_to_different_club }
        end
      else
        { message: "Subscription plan not found", code: Settings.error_codes.not_found }
      end
    else
      { message: "Member status does not allows us to change the subscription plan.", code: Settings.error_codes.user_status_dont_allow }
    end
  end

  def save_the_sale(new_tom_id, agent = nil, date = nil, additional_actions = {})
    new_tom = TermsOfMembership.find(new_tom_id)
    if date.nil? or (date and date.to_date == Time.current.to_date)
      message = "Save the sale from TOM(#{self.terms_of_membership_id}) to TOM(#{new_tom_id})."
      operation_type = Settings.operation_types.save_the_sale
      date = nil
    else
      message = "User scheduled to be changed to TOM(#{new_tom.id}) -#{new_tom.name}- at #{date}."
      operation_type = Settings.operation_types.terms_of_membership_change_scheduled
    end
    answer = change_terms_of_membership(new_tom, message, operation_type, agent, false, nil, { utm_campaign: Membership::CS_UTM_CAMPAIGN, utm_medium: Membership::CS_UTM_MEDIUM }, date, additional_actions)

    nillify_club_cash("Removing club cash upon tom change.") if date.nil? and answer[:code] == Settings.error_codes.success and additional_actions[:remove_club_cash]
    answer
  end

  def downgrade_user
    new_tom = self.terms_of_membership.downgrade_tom
    message = "Downgraded member from TOM(#{self.terms_of_membership_id}) to TOM(#{new_tom.id})"
    answer = change_terms_of_membership(new_tom, message, Settings.operation_types.downgrade_user, nil, false, nil, { utm_campaign: Membership::CS_UTM_CAMPAIGN, utm_medium: Membership::CS_UTM_MEDIUM_DOWNGRADE })
    if answer[:code] != Settings.error_codes.success
      Auditory.report_issue(answer[:message], nil, { user: self.id, answer: answer })
    else
      self.bill_date = current_membership.join_date + terms_of_membership.provisional_days.days
      self.next_retry_bill_date = current_membership.join_date + terms_of_membership.provisional_days.days
      self.save(validate: false)  
    end
    answer
  end

  # Recovers the member. Changes status from lapsed to applied or provisional (according to members term of membership.)
  def recover(new_tom, agent = nil, options = {})
    membership_params = options.merge({
      utm_campaign: Membership::CS_UTM_CAMPAIGN,
      utm_medium: Membership::CS_UTM_MEDIUM,
      campaign_description: Membership::CS_CAMPAIGN_DESCRIPTION
    })
    enroll(new_tom, self.active_credit_card, 0.0, agent, true, 0, membership_params, true, false)
  end

  def has_problems_to_bill?
    if not self.club.billing_enable
      { message: "User's club is not allowing billing", code: Settings.error_codes.user_club_dont_allow }
    elsif not status_enable_to_bill?
      { message: "User is not in a billing status.", code: Settings.error_codes.user_status_dont_allow }
    elsif not is_billing_expected?
      { message: "User is not expected to get billed.", code: Settings.error_codes.user_not_expecting_billing }
    else
      false
    end
  end

  def bill_membership
    trans = nil
    validation = has_problems_to_bill?
    if not validation and self.next_retry_bill_date.to_date <= Time.zone.now.to_date
      amount = terms_of_membership.installment_amount
      if payment_gateway_configuration.nil?
        message = "TOM ##{terms_of_membership.id} does not have a gateway configured."
        Auditory.audit(nil, terms_of_membership, message, self, Settings.operation_types.membership_billing_without_pgc)
        Auditory.notify_pivotal_tracker(message, '', { user: self.id, membership: current_membership.id })
        { code: Settings.error_codes.tom_wihtout_gateway_configured, message: message }
      else
        credit_card = active_credit_card
        credit_card.recycle_expired_rule(recycled_times)
        trans = Transaction.obtain_transaction_by_gateway!(payment_gateway_configuration.gateway)
        trans.transaction_type = "sale"
        trans.response_result = I18n.t('error_messages.airbrake_error_message')
        trans.response = { message: message } 
        trans.prepare(self, credit_card, amount, payment_gateway_configuration, nil, nil, Settings.operation_types.membership_billing)
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
      { message: "We haven't reach next bill date yet.", code: Settings.error_codes.billing_date_not_reached }
    else
      validation
    end
  rescue Exception => e
    logger.error "Membership Billing Unexpected Error: #{e.inspect}"
    trans.delete if trans
    { message: I18n.t('error_messages.airbrake_error_message'), code: Settings.error_codes.membership_billing_error } 
  end

  def no_recurrent_billing(amount, description, type)
    trans = nil
    if amount.blank? or description.blank? or type.blank?
      answer = { message: "Amount, description and type cannot be blank.", code: Settings.error_codes.wrong_data }
    elsif not Transaction::ONE_TIME_BILLINGS.include? type
      answer = { message: "Type should be 'one-time' or 'donation'.", code: Settings.error_codes.wrong_data }
    elsif amount.to_f <= 0.0
      answer = { message: "Amount must be greater than 0.", code: Settings.error_codes.wrong_data }
    else
      if billing_enabled?
        trans = Transaction.obtain_transaction_by_gateway!(payment_gateway_configuration.gateway)
        trans.transaction_type = "sale"
        trans.prepare_no_recurrent(self, active_credit_card, amount, payment_gateway_configuration, nil, nil, type)
        answer = trans.process
        if trans.success?
          message = "Member billed successfully $#{amount} Transaction id: #{trans.id}. Reason: #{description}"
          trans.update_attribute :response_result, trans.response_result+". Reason: #{description}"
          answer = { message: message, code: Settings.error_codes.success }
          Auditory.audit(nil, trans, answer[:message], self, trans.operation_type)
        else
          answer = { message: trans.response_result, code: Settings.error_codes.no_reccurent_billing_error }
          operation_type = trans.one_time_type? ? Settings.operation_types.no_recurrent_billing_with_error : Settings.operation_types.no_recurrent_billing_donation_with_error
          trans.update_attribute :operation_type, operation_type
          Auditory.audit(nil, trans, answer[:message], self, operation_type)
        end
      else
        if not self.club.billing_enable
          answer = { message: "Member's club is not allowing billing", code: Settings.error_codes.user_club_dont_allow }
        else
          answer = { message: "Member is not in a billing status.", code: Settings.error_codes.user_status_dont_allow }
        end
      end
    end
    answer
  rescue Exception => e
    trans.update_attribute :operation_type, Settings.operation_types.no_recurrent_billing_with_error if trans
    Auditory.report_issue("Billing:no_recurrent_billing", e, { user: self.id, amount: amount, description: description })
    { message: I18n.t('error_messages.airbrake_error_message'), code: Settings.error_codes.no_reccurent_billing_error }
  end

  def manual_billing(amount, payment_type)
    trans = nil
    validation = has_problems_to_bill?
    if not validation
      if amount.blank? or payment_type.blank?
        answer = { message: "Amount and payment type cannot be blank.", code: Settings.error_codes.wrong_data }
      elsif amount.to_f < current_membership.terms_of_membership.installment_amount
        answer = { message: "Amount to bill cannot be less than subscription plan installment amount.", code: Settings.error_codes.manual_billing_with_less_amount_than_permitted }
      else
        trans = Transaction.new
        trans.transaction_type = "sale_manual_#{payment_type}"
        operation_type = Settings.operation_types["membership_manual_#{payment_type}_billing"]
        trans.prepare_for_manual(self, amount, operation_type)
        trans.process
        answer = proceed_with_manual_billing_logic(trans, operation_type)
        unless self.manual_payment
          self.manual_payment = true 
          self.save(validate: false)
        end
        answer
      end
    else
      validation
    end
  rescue Exception => e
    logger.error e.inspect
    trans.update_attribute :operation_type, Settings.operation_types.manual_billing_with_error if trans
    Auditory.report_issue("Billing:manual_billing", e, { user: self.id, amount: amount, payment_type: payment_type })
    { message: I18n.t('error_messages.airbrake_error_message'), code: Settings.error_codes.membership_billing_error } 
  end

  def error_to_s(delimiter = "\n")
    self.errors.collect {|attr, message| "#{attr}: #{message}" }.join(delimiter)
  end

  def errors_merged(credit_card)
    errors = self.errors.to_hash
    errors.merge!(credit_card: credit_card.errors.to_hash) unless credit_card.errors.empty?
    errors
  end

  def self.enroll(tom, current_agent, enrollment_amount, user_params, credit_card_params, cc_blank = false, skip_api_sync = false)
    credit_card_params = {} if credit_card_params.blank? # might be [], we expect a Hash
    credit_card_params = { number: '0000000000', expire_year: Time.zone.now.year, expire_month: Time.zone.now.month } if cc_blank
    club = tom.club

    unless club.billing_enable
      return { message: I18n.t('error_messages.club_is_not_enable_for_new_enrollments', cs_phone_number: club.cs_phone_number), code: Settings.error_codes.club_is_not_enable_for_new_enrollments }      
    end

    user = User.find_by(email: user_params[:email], club_id: club.id)
    # credit card exist? . we need this token for CreditCard.joins(:member) and enrollment billing.
    credit_card = CreditCard.new number: credit_card_params[:number], expire_year: credit_card_params[:expire_year], expire_month: credit_card_params[:expire_month]

    if user.nil?
      user = User.new
      user.update_user_data_by_params user_params
      user.skip_api_sync! if skip_api_sync
      user.club = club
      credit_card.get_token(tom.payment_gateway_configuration, user, cc_blank)
      unless user.valid? and credit_card.errors.size == 0
        return { message: I18n.t('error_messages.user_data_invalid'), code: Settings.error_codes.user_data_invalid, 
                 errors: user.errors_merged(credit_card) }
      end
    elsif user.blacklisted
      message = I18n.t('error_messages.user_email_blacklisted', cs_phone_number: club.cs_phone_number)
      Auditory.audit(current_agent, tom, message, user, Settings.operation_types.user_email_blacklisted)
      return { message: message, code: Settings.error_codes.user_email_blacklisted, errors: {blacklisted: "Member is blacklisted"} }
    else
      user.skip_api_sync! if skip_api_sync
      # first update first name and last name, then validate credit card
      user.update_user_data_by_params user_params
      credit_card.get_token(tom.payment_gateway_configuration, user, cc_blank)
      return { message: I18n.t('error_messages.user_data_invalid'), code: Settings.error_codes.user_data_invalid, 
                 errors: user.errors_merged(credit_card) } unless credit_card.errors.size == 0
    end

    answer = user.validate_if_credit_card_already_exist(tom, credit_card, true, cc_blank, current_agent)
    if answer[:code] == Settings.error_codes.success
      user.enroll(tom, credit_card, enrollment_amount, current_agent, true, cc_blank, user_params, false, false)
    else
      answer
    end
  end

  def replenish_stock_on_enrollment_failure(product_id)
    Product.where(id: product_id).update_all "stock = stock + 1"
  end

  def enroll(tom, credit_card, amount, agent = nil, recovery_check = true, cc_blank = false, user_params = nil, skip_credit_card_validation = false, skip_product_validation = false, skip_user_validation = false)
    allow_cc_blank = (amount.to_f == 0.0 and cc_blank)
    club = tom.club

    if not self.new_record? and recovery_check and not self.lapsed? 
      return { :message => I18n.t('error_messages.user_already_active', :cs_phone_number => club.cs_phone_number), :code => Settings.error_codes.user_already_active, :errors => { :status => "Already active." } }
    elsif recovery_check and not self.new_record? and not self.can_recover?
      return { :message => I18n.t('error_messages.cant_recover_user', :cs_phone_number => club.cs_phone_number), :code => Settings.error_codes.cant_recover_user }
    end

    product = nil
    if not skip_product_validation and not user_params[:product_sku].blank?
      product = Product.find_by(club_id: club.id, sku: user_params[:product_sku])
      if product.nil?
        return { message: I18n.t('error_messages.product_does_not_exists'), code: Settings.error_codes.product_does_not_exists }
      else
        result = product.decrease_stock
        return result if result[:code] != Settings.error_codes.success
      end
    end

    # CLEAN ME: => This validation is done at self.enroll
    if not skip_user_validation and not self.valid? 
      replenish_stock_on_enrollment_failure(product.id) if not skip_product_validation and product
      return { message: I18n.t('error_messages.user_data_invalid'), code: Settings.error_codes.user_data_invalid, 
               errors: self.errors_merged(credit_card) }
    end

    begin
      operation_type = check_enrollment_operation(tom)
      if amount.to_f != 0.0 or (amount.to_f == 0.0 and tom.payment_gateway_configuration.payeezy? and not skip_credit_card_validation)
        trans = Transaction.obtain_transaction_by_gateway!(tom.payment_gateway_configuration.gateway)
        trans.transaction_type = amount.to_f != 0.0 ? "sale" : "authorization"
        trans.prepare(self, credit_card, amount, tom.payment_gateway_configuration, tom.id, nil, operation_type)
        answer = trans.process
        unless trans.success? 
          operation_type = Settings.operation_types.error_on_enrollment_billing
          Auditory.audit(agent, trans, "Transaction was not successful.", self, operation_type) 
        # TODO: Make sure to leave an operation related to the prospect if we have prospects and users merged in one unique table.
          trans.operation_type = operation_type
          trans.save
          replenish_stock_on_enrollment_failure(product.id) if not skip_product_validation and product
          return answer
        end
      end

      if self.new_record?
        self.credit_cards << credit_card
        self.save! validate: !skip_user_validation
      elsif not skip_credit_card_validation
        self.save! validate: !skip_user_validation
        validate_if_credit_card_already_exist(tom, credit_card, false, cc_blank, agent)
        credit_card = active_credit_card
      end

      membership = Membership.new(terms_of_membership_id: tom.id, created_by: agent, enrollment_amount: amount)
      membership.update_membership_info_by_hash user_params
      membership.product = product
      membership.user = self
      membership.save!

      self.update_attribute :current_membership_id, membership.id

      if trans
        # We cant assign this information before , because models must be created AFTER transaction
        # is completed succesfully
        trans.user_id = self.id
        trans.credit_card_id = credit_card.id
        trans.membership_id = self.current_membership.id
        trans.last_digits = credit_card.last_digits
        trans.save
        credit_card.accepted_on_billing
      end
      self.reload
      message = set_status_on_enrollment!(agent, trans, amount, membership, operation_type)

      { 
        message: message,
        code: Settings.error_codes.success,
        member_id: id,
        autologin_url: full_autologin_url.to_s,
        status: status,
        api_role: tom.api_role.to_s.split(','),
        bill_date: (next_retry_bill_date.nil? ? '' : self.next_retry_bill_date.strftime("%m/%d/%Y"))
      }
    rescue Exception => e
      logger.error e.inspect
      error_message = (self.id.nil? ? "User:enroll" : "User:recovery/save the sale") + " -- user turned invalid while enrolling"
      replenish_stock_on_enrollment_failure(product.id) if not skip_product_validation and product
      trans.update_attribute(:operation_type, Settings.operation_types.error_on_enrollment_billing) if trans and not trans.success
      Auditory.report_issue(error_message, e, { user: self.id, credit_card: credit_card.id, membership: membership.id })
      # TODO: this can happend if in the same time a new member is enrolled that makes this an invalid one. Do we have to revert transaction?
      # TODO2: Make sure to leave an operation related to the prospect if we have prospects and users merged in one unique table.
      Auditory.audit(agent, self, error_message, self, Settings.operation_types.error_on_enrollment_billing) unless self.new_record?
      { message: I18n.t('error_messages.user_not_saved', cs_phone_number: self.club.cs_phone_number), code: Settings.error_codes.user_not_saved }
    end
  end

  def proceed_to_bill_prorated_amount(agent, tom, amount_in_favor, credit_card, sale_transaction = nil, operation_type)
    amount_to_process = ((tom.installment_amount - amount_in_favor)*100).round / 100.0

    if amount_to_process >= 0
      trans = Transaction.obtain_transaction_by_gateway!(tom.payment_gateway_configuration.gateway)
      trans.transaction_type = "sale"
      trans.prepare(self, credit_card, amount_to_process, tom.payment_gateway_configuration, tom.id, nil, operation_type)
      answer = trans.process
    else
      answer = Transaction.refund(amount_to_process.abs, sale_transaction.id, agent, false, operation_type)
      self.reload
      trans = self.transactions.last
    end
    return trans, answer
  end

  def prorated_enroll(tom, agent = nil, credit_card_params = nil, user_params = nil, skip_user_validation = false)
    return { message: I18n.t('error_messages.prorated_enroll_failure', cs_phone_number: self.club.cs_phone_number), code: Settings.error_codes.error_on_prorated_enroll } if tom.needs_enrollment_approval
    if credit_card_params and not credit_card_params.empty?
      response = self.update_credit_card_from_drupal(credit_card_params, agent) 
      if response[:code] != Settings.error_codes.success
        return response
      end
      credit_card = CreditCard.find(response[:credit_card_id])
    else
      credit_card = self.active_credit_card
    end

    if not skip_user_validation and not self.valid?
      return { message: I18n.t('error_messages.user_data_invalid'), code: Settings.error_codes.user_data_invalid, errors: self.errors.to_hash }
    end

    former_membership = self.current_membership
    amount_in_favor = installment_amount_not_used
    operation_type = Settings.operation_types.tom_change_billing
    new_membership = Membership.new(terms_of_membership_id: tom.id, created_by: agent)
    if self.active?
      base = transactions.where('terms_of_membership_id = ? and operation_type in (?)', terms_of_membership_id, Settings.operation_types.membership_billing)
      sale_transaction = base.last
      if (sale_transaction and sale_transaction.refunded_amount != 0.0) or (not sale_transaction and transactions.where('terms_of_membership_id = ? and operation_type in (?)', terms_of_membership_id, Settings.operation_types.tom_change_billing).first)
        return { message: I18n.t('error_messages.prorated_enroll_failure', cs_phone_number: self.club.cs_phone_number), code: Settings.error_codes.error_on_prorated_enroll }
      end
      club_cash_to_deduct = club_cash_not_used(base.count == 1)
      trans, answer = proceed_to_bill_prorated_amount(agent, tom, amount_in_favor, credit_card, sale_transaction, operation_type)
      message = "Membership prorated successfully. Billing $#{tom.installment_amount} minus $#{amount_in_favor} that had in favor related for TOM(#{tom.id}) -#{tom.name}-. Final amount #{trans.transaction_type=='sale' ? 'billed' : 'refunded'} $#{trans.amount}."
    else
      days_already_in_provisional = (Time.zone.now.to_date - join_date.to_date ).to_i
      club_cash_to_deduct = 0.0
      if days_already_in_provisional >= tom.provisional_days
        trans, answer = proceed_to_bill_prorated_amount(agent, tom, 0.0, credit_card, nil, operation_type) 
        message = "Membership reached end of provisional period after Subscription Plan change to TOM(#{tom.id}) -#{tom.name}-. Billing $#{trans.amount} according to new installment amount."
      else
        operation_type = Settings.operation_types.enrollment_billing
      end
    end

    if trans 
      unless trans.success?
        operation_type = Settings.operation_types.tom_change_billing_with_error
        Auditory.audit(agent, trans, "Transaction was not successful.", self, operation_type)
        trans.operation_type = operation_type
        trans.membership_id = nil
        trans.save
        return answer
      end
      Auditory.audit(agent, trans, message, self, operation_type)
    end
    
    begin
      membership = Membership.new(terms_of_membership_id: tom.id)
      membership.update_membership_info_by_hash user_params
      self.current_membership = membership
      self.memberships << new_membership
      self.current_membership = new_membership
      self.save
      
      if trans
        trans.membership_id = self.current_membership.id
        trans.terms_of_membership_id = tom.id
        trans.save
      end
      credit_card.accepted_on_billing
      message = set_status_on_enrollment!(agent, trans, 0.0, membership, operation_type)
      
      if trans
        proceed_with_prorated_logic(agent, trans, amount_in_favor, former_membership, club_cash_to_deduct, sale_transaction)
      else
        new_next_bill_date = (self.join_date + tom.provisional_days.days) - days_already_in_provisional.days
        new_next_bill_date = Time.zone.now if new_next_bill_date.to_date < Time.zone.now.to_date
        new_next_bill_date = new_next_bill_date.in_time_zone(self.club.time_zone)
        change_next_bill_date(new_next_bill_date, agent, "Moved next bill date due to Tom change. Already spend #{days_already_in_provisional} days in previous membership.")
      end

      { 
        message: message, 
        code: Settings.error_codes.success, 
        member_id: id, 
        autologin_url: full_autologin_url.to_s,
        status: status,
        api_role: tom.api_role.to_s.split(','),
        bill_date: (next_retry_bill_date.nil? ? '' : self.next_retry_bill_date.strftime("%m/%d/%Y"))
      }
    rescue Exception => e
      logger.error e.inspect
      Auditory.report_issue("User:prorated_enroll -- user turned invalid while enrolling", e, { user: self.id, credit_card: credit_card.id, membership: membership.id })
      # TODO: this can happend if in the same time a new member is enrolled that makes this an invalid one. Do we have to revert transaction?
      Auditory.audit(agent, self, "User:prorated_enroll", self, Settings.operation_types.tom_change_billing_with_error)
      { message: I18n.t('error_messages.user_not_saved', cs_phone_number: self.club.cs_phone_number), code: Settings.error_codes.user_not_saved }
    end
  end

  def send_pre_bill
    Communication.deliver!( self.manual_payment ? :manual_payment_prebill : :prebill, self) if membership_billing_enabled?
  end

  def sync?
    self.club.sync?
  end

  def api_user
    @api_user ||= if !self.sync?
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
    self.api_user && self.api_user.login_token rescue nil
  end

  def full_autologin_url
    c = self.club
    d = c.api_domain if c

    if d and self.autologin_url.present?
      URI.parse(d.url) + self.autologin_url
    else
      nil
    end
  end

  ##################### Club cash ####################################
  
  def is_cms_configured?
    @is_cms_configured  ||= club.is_cms_configured?
  end
  
  def is_spree?
    @is_spree ||= club.is_spree?
  end

  def is_drupal?
    @is_drupal ||= club.is_drupal?
  end

  # Resets user club cash in case of a cancelation.
  def nillify_club_cash(message = 'Removing club cash because of member cancellation')
    Users::NillifyClubCashJob.perform_later(self.id, message)
  end
  
  def nillify_club_cash_upon_cancellation
    message = 'Removing club cash because of member cancellation'
    if is_drupal?
      self.club_cash_amount = 0
      self.save
      Auditory.audit(nil, self, message, self, Settings.operation_types.reset_club_cash)
    else
      nillify_club_cash
    end
  end

  # Resets member club cash in case the club cash has expired.
  def reset_club_cash
    Users::ResetClubCashJob.perform_later(user_id: self.id)
  end

  def assign_first_club_cash 
    assign_club_cash unless terms_of_membership.skip_first_club_cash
  end

  # Adds club cash when membership billing is success. Only on each 12th month, and if it is not the first billing.
  def assign_club_cash(message = "Adding club cash after billing", enroll = false)   
    Users::AssignClubCashJob.set(wait: 5.minutes).perform_later(self.id, message, enroll)
  end

  # Adds club cash transaction. 
  def add_club_cash(agent, amount = 0, description = nil, set_expire_date = false)
    answer = { code: Settings.error_codes.club_cash_transaction_not_successful, message: "Could not save club cash transaction"  }
    begin
      if not club.allow_club_cash_transaction?
        answer = { message: I18n.t("error_messages.club_cash_not_supported"), code: Settings.error_codes.club_does_not_support_club_cash }
      elsif amount.to_f == 0
        answer[:message] = I18n.t("error_messages.club_cash_transaction_invalid_amount")
        answer[:errors] = { amount: "Invalid amount" } 
      elsif !is_drupal?
        ClubCashTransaction.transaction do
          begin
            if (amount.to_f < 0 and amount.to_f.abs <= self.club_cash_amount) or amount.to_f > 0
              cct = ClubCashTransaction.new(amount: amount, description: description)
              self.club_cash_transactions << cct
              raise "Could not save club cash transaction" unless cct.valid? and self.valid?
              self.club_cash_amount       = self.club_cash_amount + amount.to_f
              self.club_cash_expire_date  = Time.current.to_date + 1.year if set_expire_date
              self.save(validate: false)
              message = "#{cct.amount.to_f.abs} club cash was successfully #{ amount.to_f >= 0 ? 'added' : 'deducted' }."+(description.blank? ? '' : " Concept: #{description}")
              if amount.to_f > 0
                Auditory.audit(agent, cct, message, self, Settings.operation_types.add_club_cash)
              elsif amount.to_f < 0 and amount.to_f.abs == club_cash_amount 
                Auditory.audit(agent, cct, message, self, Settings.operation_types.reset_club_cash)
              elsif amount.to_f < 0 
                Auditory.audit(agent, cct, message, self, Settings.operation_types.deducted_club_cash)
              end
              answer = { message: message, code: Settings.error_codes.success }
            else
              answer[:message] = "You can not deduct #{amount.to_f.abs} because the user only has #{self.club_cash_amount} club cash."
              answer[:errors] = { amount: "Club cash amount is greater that user's actual club cash." }
            end
          rescue Exception => e
            answer[:errors] = cct.errors_merged(self) unless cct.nil?
            Auditory.report_issue('Club cash Transaction', e, { answer_message: answer[:message], user: self.id, amount: amount, description: description, club_cash_transaction: cct.try(:id) })
            answer[:message] = I18n.t('error_messages.airbrake_error_message')
            raise ActiveRecord::Rollback
          end
        end
      elsif not api_id.nil?
        Drupal::UserPoints.new(self).create!({amount: amount, description: description})
        message = last_sync_error || "Club cash processed at drupal correctly. Amount: #{amount}. Concept: #{description}"
        auditory_code = Settings.operation_types.remote_club_cash_transaction_failed
        if self.last_sync_error.nil?
          auditory_code = Settings.operation_types.remote_club_cash_transaction
          answer = { message: message, code: Settings.error_codes.success }
        else
          answer = { message: last_sync_error, code: Settings.error_codes.club_cash_transaction_not_successful }
        end
        answer[:message] = I18n.t('error_messages.drupal_error_sync') if message.blank?
        Auditory.audit(agent, self, answer[:message], self, auditory_code)
      end
    rescue Exception => e
      Auditory.report_issue('Club cash Transaction', e, { answer_message: answer[:message], user: self.id, amount: amount, description: description })
      answer[:message] = I18n.t('error_messages.airbrake_error_message')
      answer[:errors] = { amount: "There has been an error while adding club cash amont." }
    end
    answer
  end

  def unblacklist(agent = nil, reason = '', unblacklist_type = 'permanent')
    answer = { message: "Member already blacklisted", success: false }
    if self.blacklisted?
      User.transaction do
        begin
          operation = Settings.operation_types.unblacklisted
          message = "Unblacklisted member and all its credit cards. Reason: #{reason}"
          if unblacklist_type == 'temporary'
            operation = Settings.operation_types.unblacklisted_temporary
            message = "Temporary unblacklisted member and all its credit cards. Reason: #{reason}"
          end
          self.blacklisted = false
          self.save(validate: false)
          Auditory.audit(agent, self, message, self, operation  )
          self.credit_cards.each { |cc| cc.unblacklist }
          answer = { message: message, code: Settings.error_codes.success }
        rescue Exception => e
          Auditory.report_issue("User::unblacklist", e, { user: self.id })
          answer = { message: I18n.t('error_messages.airbrake_error_message') + e.to_s, code: Settings.error_codes.user_could_not_be_unblacklisted }
          raise ActiveRecord::Rollback
        end
      end
      marketing_tool_sync_subscription unless self.blacklisted?
    end
    answer
  end

  def blacklist(agent, reason)
    answer = { message: "Member already blacklisted", success: false }
    unless self.blacklisted?
      User.transaction do 
        begin
          self.blacklisted = true
          self.save(validate: false)
          message = "Blacklisted member and all its credit cards. Reason: #{reason}."
          Auditory.audit(agent, self, message, self, Settings.operation_types.blacklisted)
          self.credit_cards.each { |cc| cc.blacklist }
          unless self.lapsed?
            self.cancel! Time.zone.now.in_time_zone(get_club_timezone), "Automatic cancellation"
            self.set_as_canceled!
          end
          answer = { message: message, code: Settings.error_codes.success }
        rescue Exception => e
          Auditory.report_issue("User::blacklist", e, { user: self.id })
          answer = { message: I18n.t('error_messages.airbrake_error_message')+e.to_s, success: Settings.error_codes.user_could_no_be_blacklisted }
          raise ActiveRecord::Rollback
        end
      end
    end
    answer
  end
  ###################################################################

  def update_user_data_by_params(params)
    [ :first_name, :last_name, :address, :state, :city, :country, :zip,
      :email, :birth_date, :gender,
      :phone_country_code, :phone_area_code, :phone_local_number, 
      :member_group_type_id, :preferences, :external_id, :manual_payment ].each do |key|
          self.send("#{key}=", params[key]) if params.include? key
    end
    self.type_of_phone_number = params[:type_of_phone_number].to_s.downcase if params.include? :type_of_phone_number
  end

  def chargeback!(transaction_chargebacked, args, reason = '')
    if can_be_chargeback?
      begin
        trans = Transaction.obtain_transaction_by_gateway!(transaction_chargebacked.gateway)
        trans.new_chargeback!(transaction_chargebacked, args)
        self.blacklist nil, "Chargeback - " + reason
      rescue NonReportableException
        # do nothing
      rescue ActiveRecord::RecordNotSaved
        raise trans.errors.messages.map{|k,v| "#{k.to_s.humanize}: #{v.join(', ')}"}.join(".")
      rescue Exception => e
        Auditory.report_issue("Users::chargeback", e, { :user => self.id, :transaction => trans.id })
        raise I18n.t("error_messages.airbrake_error_message")
      end
    else
      raise "User cannot be chargebacked."
    end
  end

  def cancel!(cancel_date, message, current_agent = nil, operation_type = Settings.operation_types.future_cancel)
    cancel_date = cancel_date.to_date
    cancel_date = (self.join_date.in_time_zone(get_club_timezone).to_date == cancel_date ? "#{cancel_date} 23:59:59" : cancel_date).to_datetime
    if not message.blank?
      if cancel_date.change(offset: self.get_offset_related(cancel_date)).to_date >= Time.new.getlocal(self.get_offset_related).to_date
        if self.cancel_date == cancel_date
          answer = { message: "Cancel date is already set to that date", code: Settings.error_codes.wrong_data }
        else
          if can_be_canceled?
            self.current_membership.update_attribute :cancel_date, cancel_date.change(offset: self.get_offset_related(cancel_date))
            answer = { message: "Member cancellation scheduled to #{cancel_date.to_date} - Reason: #{message}", code: Settings.error_codes.success }
            Auditory.audit(current_agent, self, answer[:message], self, operation_type)
          else
            answer = { message: "Member is not in cancelable status.", code: Settings.error_codes.cancel_date_blank }
          end
        end
      else
        answer = { message: "Cancellation date cannot be less or equal than today.", code: Settings.error_codes.wrong_data }
      end
    else 
      answer = { message: "Reason missing. Please, make sure to provide a reason for this cancelation.", code: Settings.error_codes.cancel_reason_blank }
    end 
    return answer
  end
  
  def set_wrong_address(agent, reason, set_fulfillments = true)
    if self.wrong_address.nil?
      if self.update_attribute(:wrong_address, reason)
        if set_fulfillments
          self.fulfillments.where_to_set_bad_address.each do |fulfillment| 
            fulfillment.update_status(nil, 'bad_address', "User set as undeliverable")
          end
        end
        message = "Address #{self.full_address} is undeliverable. Reason: #{reason}"
        Auditory.audit(agent, self, message, self, Settings.operation_types.user_address_set_as_undeliverable)
        { message: message, code: Settings.error_codes.success }
      else
        message = I18n.t('error_messages.user_set_wrong_address_error', errors: self.errors.inspect)
        {message: message, code: Settings.error_codes.user_set_wrong_address_error}
      end
    else
      message = I18n.t('error_messages.user_set_wrong_address_error', errors: '')
      { message: message, code: Settings.error_codes.user_already_set_wrong_address }
    end
  end

  def self.supported_states(country='US')
    if country == 'US'
      Carmen::Country.coded('US').subregions.select{ |s| %w{AK AL AR AZ CA CO CT DC DE 
        FL GA HI IA ID IL IN KS KY LA MA MD ME MI MN MO MS MT NC ND NE NH  NJ NM NV NY 
        OH OK OR PA RI SC SD TN TX UT VA VI VT WA WI WV WY}.include?(s.code) }
    else
      Carmen::Country.coded('CA').subregions
    end
  end

  def validate_if_credit_card_already_exist(tom, credit_card, only_validate = true, allow_cc_blank = false, current_agent = nil, set_active = true)
    new_month, new_year, new_number = credit_card["expire_month"], credit_card["expire_year"], (credit_card["number"] || credit_card.number).to_s
    answer = { message: "Credit card valid", code: Settings.error_codes.success}
    family_memberships_allowed = tom.club.family_memberships_allowed
    new_credit_card = CreditCard.new(number: new_number, expire_month: new_month, expire_year: new_year, token: credit_card["token"], cc_type: credit_card.try(:cc_type))
    new_credit_card.get_token(tom.payment_gateway_configuration, self)

    credit_cards = if new_credit_card.token.nil?
      []
    elsif new_credit_card.token == CreditCard::BLANK_CREDIT_CARD_TOKEN
      self.credit_cards.where(token: CreditCard::BLANK_CREDIT_CARD_TOKEN)
    else
      CreditCard.joins(:user).where(token: new_credit_card.token, users: { :club_id => club.id } )
    end

    if credit_cards.empty? or allow_cc_blank
      unless only_validate
        answer          = add_new_credit_card(new_credit_card, current_agent, set_active)
        new_credit_card = active_credit_card if set_active
      end
    # credit card is blacklisted
    elsif not credit_cards.select { |cc| cc.blacklisted? }.empty? 
      answer = { message: I18n.t('error_messages.credit_card_blacklisted', cs_phone_number: self.club.cs_phone_number), code: Settings.error_codes.credit_card_blacklisted, errors: { number: "Credit card is blacklisted" }}
    # is this credit card already of this members and its already active?
    elsif not credit_cards.select { |cc| cc.user_id == self.id and cc.active }.empty? 
      unless only_validate
        answer          = active_credit_card.update_expire(new_year, new_month, current_agent) # lets update expire month
        new_credit_card = active_credit_card
      end
    elsif not family_memberships_allowed and not credit_cards.select { |cc| cc.user_id == self.id and not cc.active }.empty? and not credit_cards.select { |cc| cc.user_id != self.id and cc.active }.empty?
      answer = { message: I18n.t('error_messages.credit_card_in_use', cs_phone_number: self.club.cs_phone_number), code: Settings.error_codes.credit_card_in_use, errors: { number: "Credit card is already in use" }}
    # is this credit card already of this member but its inactive? and we found another credit card assigned to another member but in inactive status?
    elsif not credit_cards.select { |cc| cc.user_id == self.id and not cc.active }.empty? and (family_memberships_allowed or credit_cards.select { |cc| cc.user_id != self.id and cc.active }.empty?)
      unless only_validate
        new_credit_card = CreditCard.find credit_cards.select { |cc| cc.user_id == self.id }.first.id
        CreditCard.transaction do 
          begin
            answer = new_credit_card.update_expire(new_year, new_month, current_agent) # lets update expire month
            if answer[:code] == Settings.error_codes.success
              # activate new credit card ONLY if expire date was updated.
              new_credit_card.set_as_active! if set_active
            end
          rescue Exception => e
            Auditory.report_issue("Users::update_credit_card_from_drupal", e, { new_active_credit_card: new_credit_card.try(:id), user: self.id })
            raise ActiveRecord::Rollback
          end
        end
      end
    # its not my credit card. its from another member. the question is. can I use it?
    elsif family_memberships_allowed or credit_cards.select { |cc| cc.active }.empty? 
      unless only_validate
        answer = add_new_credit_card(new_credit_card, current_agent, set_active)
        new_credit_card = active_credit_card if set_active
      end
    else
      answer = { message: I18n.t('error_messages.credit_card_in_use', cs_phone_number: self.club.cs_phone_number), code: Settings.error_codes.credit_card_in_use, errors: { number: "Credit card is already in use" }}
    end
    answer[:code]==Settings.error_codes.success ? answer.merge!(credit_card_id: new_credit_card.id) : answer
  end

  def update_credit_card_from_drupal(credit_card, current_agent = nil)
    return { code: Settings.error_codes.success } if credit_card.nil? || credit_card.empty?
    new_year, new_month, new_number = credit_card[:expire_year], credit_card[:expire_month], nil

    if self.blacklisted
      return { code: Settings.error_codes.blacklisted, message: I18n.t('error_messages.user_set_as_blacklisted') }
    end

    # Drupal sends X when member does not change the credit card number      
    if credit_card[:number].blank?
      { code: Settings.error_codes.invalid_credit_card, message: I18n.t('error_messages.invalid_credit_card'), errors: { number: "Credit card is blank." }}
    elsif credit_card[:number].to_s.include?('X')
      if active_credit_card.last_digits.to_s == credit_card[:number].to_s[-4..-1] # lets update expire month
        answer = active_credit_card.update_expire(new_year, new_month, current_agent)
        answer.merge!(credit_card_id: active_credit_card.id)
      else # do not update nothing, credit cards do not match or its expired
        { code: Settings.error_codes.invalid_credit_card, message: I18n.t('error_messages.invalid_credit_card'), errors: { number: "Credit card do not match the active one." }}
      end
    else # drupal or CS sends the complete credit card number.
      set_as_active = credit_card[:set_active].nil? ? true : credit_card[:set_active].to_s.to_bool
      validate_if_credit_card_already_exist(terms_of_membership, credit_card, false, false, current_agent, set_as_active)
    end
  end

  def add_new_credit_card(new_credit_card, current_agent = nil, set_active = true)
    answer = {}
    CreditCard.transaction do 
      begin    
        new_credit_card.user = self
        new_credit_card.active = set_active
        new_credit_card.gateway = terms_of_membership.payment_gateway_configuration.gateway if new_credit_card.gateway.nil?
        if new_credit_card.errors.size == 0
          new_credit_card.save!
          message = "Credit card #{new_credit_card.last_digits} added" + (set_active ? " and activated." : ".")
          Auditory.audit(current_agent, new_credit_card, message, self, Settings.operation_types.credit_card_added)
          answer = { code: Settings.error_codes.success, message: message }
          new_credit_card.set_as_active! if set_active
        else
          answer = { code: Settings.error_codes.invalid_credit_card, message: I18n.t('error_messages.invalid_credit_card'), errors: new_credit_card.errors.to_hash }
        end        
      rescue Exception => e
        answer = { errors: e, message: I18n.t('error_messages.airbrake_error_message'), code: Settings.error_codes.invalid_credit_card }
        Auditory.report_issue("User:update_credit_card", e, { user: self.id, credit_card: new_credit_card.try(:id) })
        raise ActiveRecord::Rollback
      end
    end
    answer
  end

  def desnormalize_additional_data
    Users::DesnormalizeAdditionalDataJob.perform_later(user_id: self.id)
  end

  def desnormalize_preferences
    Users::DesnormalizePreferencesJob.perform_later(user_id: self.id)
  end

  def marketing_tool_sync
    case(club.marketing_tool_client)
    when 'exact_target'
      marketing_tool_exact_target_sync if defined?(SacExactTarget::MemberModel)
    when 'mailchimp_mandrill'
      Mailchimp::UserSynchronizationJob.perform_later(self.id) if defined?(SacMailchimp::MemberModel)
    end
  end

  # used for member blacklist
  def marketing_tool_sync_unsubscription(with_delay = true)
    case(club.marketing_tool_client)
    when 'exact_target'
      if defined?(SacExactTarget::MemberModel)
        with_delay ? exact_target_unsubscribe : exact_target_unsubscribe_without_delay 
      end
    when 'mailchimp_mandrill'
      if defined?(SacMailchimp::MemberModel)
        with_delay ? Mailchimp::UserUnsubscribeJob.perform_later(self.id) : Mailchimp::UserUnsubscribeJob.perform_now(self.id)
      end
    end
  rescue Exception => e
    logger.error "* * * * * #{e}"
    Auditory.report_issue("User::unsubscribe", e, { user: self.id })
  end

  # used for member unblacklist
  def marketing_tool_sync_subscription
    case(club.marketing_tool_client)
    when 'exact_target'
      exact_target_subscribe if defined?(SacExactTarget::MemberModel)
    when 'mailchimp_mandrill'
      Mailchimp::UserSynchronizationJob.perform_later(self.id) if defined?(SacMailchimp::MemberModel)
    end
  end
  
  def marketing_tool_remove_from_list
    case(club.marketing_tool_client)
    when 'exact_target'
      exact_target_unsubscribe if defined?(SacExactTarget::MemberModel)
    when 'mailchimp_mandrill'
      self.mailchimp_member.delete! if self.mailchimp_member
    end
  end

  def get_offset_related(date = Time.now)
    date = date.to_date
    Time.new(date.year, date.month, date.day).in_time_zone(get_club_timezone).formatted_offset
  end

  def get_club_timezone
    @club_timezone ||= self.club.time_zone
  end

  private
    def schedule_renewal(manual = false, days_already_used = 0)
      new_bill_date = Time.zone.now + terms_of_membership.installment_period.days - days_already_used.days
      # refs #15935
      self.recycled_times = 0
      self.bill_date = new_bill_date
      self.next_retry_bill_date = new_bill_date
      self.save(validate: false)
      Auditory.audit(nil, self, "Renewal scheduled. NBD set #{new_bill_date.to_date}", self, Settings.operation_types.renewal_scheduled)
    end

    def check_upgradable
      if terms_of_membership.upgradable?
        if join_date.to_date + terms_of_membership.upgrade_tom_period.days <= Time.new.getlocal(self.get_offset_related).to_date
          change_terms_of_membership(terms_of_membership.upgrade_tom_id, "Upgrade member from TOM(#{self.terms_of_membership_id}) to TOM(#{terms_of_membership.upgrade_tom_id})", Settings.operation_types.tom_upgrade, nil, false, nil, { utm_campaign: Membership::CS_UTM_CAMPAIGN, utm_medium: Membership::CS_UTM_MEDIUM_UPGRADE })
          return false
        end
      end
      true
    end

    def check_enrollment_operation(terms_of_membership)
      if terms_of_membership.needs_enrollment_approval?
        if self.lapsed?
          Settings.operation_types.recovery_needs_approval
        else
          Settings.operation_types.enrollment_needs_approval
        end
      elsif self.lapsed?
        Settings.operation_types.recovery
      else
        Settings.operation_types.enrollment_billing
      end
    end

    def set_status_on_enrollment!(agent, trans, amount, info, operation_type)
      description = 'enrolled'
      # Member approval need it?
      if terms_of_membership.needs_enrollment_approval?
        self.set_as_applied!
        # is a recovery?
        if self.lapsed?
          description = 'recovered pending approval'
        else
          description = 'enrolled pending approval'
        end
      elsif self.lapsed? # is a recovery?
        self.recovered!
        description = 'recovered'
      else      
        self.set_as_provisional! # set join_date
      end

      message = "Member #{description} successfully $#{amount} on TOM(#{terms_of_membership.id}) -#{terms_of_membership.name}-"
      Auditory.audit(agent, (trans.nil? ? terms_of_membership : trans), message, self, operation_type)
      message
    end

    def proceed_with_manual_billing_logic(trans, operation_type)
      first_time = self.provisional?
      unless set_as_active
        Auditory.report_issue("Billing:manual_billing::set_as_active - Can't set as active after manual billing", nil, { user: self.id, membership: current_membership.id, transaction_id: trans.id, transaction_amount: trans.amount, transaction_response: trans.response })
      end
      first_time ? assign_first_club_cash : assign_club_cash
      message = "Member manually billed successfully $#{trans.amount} Transaction id: #{trans.id}"
      Auditory.audit(nil, trans, message, self, operation_type)
      if check_upgradable 
        schedule_renewal(true)
      end
      { message: message, code: Settings.error_codes.success, user_id: self.id }
    end

    def proceed_with_billing_logic(trans)
      first_time = self.provisional?
      unless set_as_active
        Auditory.report_issue("Billing::set_as_active - Can't set as active this user.", nil, { user: self.id, membership: current_membership.id, transaction_id: trans.id, transaction_amount: trans.amount, transaction_response: trans.response })
      end

      Communication.deliver!(:membership_bill, self)
      if first_time 
        assign_first_club_cash 
      else
        Communication.deliver!(:membership_renewal, self)
        assign_club_cash
      end

      if check_upgradable 
        schedule_renewal
      end
      message = "Member billed successfully $#{trans.amount} Transaction id: #{trans.id}"
      Auditory.audit(nil, trans, message, self, Settings.operation_types.membership_billing)
      { message: message, code: Settings.error_codes.success, user_id: self.id }
    end

    def proceed_with_prorated_logic(agent, trans, amount_in_favor, former_membership, club_cash_to_substract, sale_transaction)
      unless set_as_active
        Auditory.report_issue("Billing::set_as_active - Can't set as active after prorated update", nil, { member: self.id, membership: current_membership.id, transaction_id: trans.id, transaction_amount: trans.amount, transaction_response: trans.response })
      end
      if amount_in_favor > 0.0
        Transaction.generate_balance_transaction(agent, self, -amount_in_favor, former_membership, sale_transaction)
        Transaction.generate_balance_transaction(agent, self, amount_in_favor, current_membership)
      end
      if club_cash_to_substract || is_spree?
        club_cash_to_add = is_spree? ? terms_of_membership.initial_club_cash_amount : terms_of_membership.club_cash_installment_amount
        club_cash_balance = club_cash_to_add.to_i - club_cash_to_substract.to_i
        club_cash_balance = -self.club_cash_amount if club_cash_balance < 0 && club_cash_balance.abs > self.club_cash_amount
        self.add_club_cash(agent, club_cash_balance, "Prorating club cash. Adding #{club_cash_to_add} minus #{club_cash_to_substract.to_i} from previous Subscription plan.", true)
      end
      schedule_renewal if check_upgradable
    end

    def record_date
      self.member_since_date = Time.zone.now
    end

    def cancellation
      self.cancel_user_at_remote_domain
      if (Time.zone.now.to_date - join_date.in_time_zone(get_club_timezone).to_date).to_i <= Settings.days_to_wait_to_cancel_fulfillments
        fulfillments.where_cancellable.each do |fulfillment| 
          fulfillment.update_status(nil, 'canceled', "Member canceled")
        end
      end
      self.next_retry_bill_date = nil
      self.bill_date = nil
      self.recycled_times = 0
      self.change_tom_attributes = nil
      self.change_tom_date = nil
      self.save(validate: false)
      Communication.deliver!(:cancellation, self)
      Auditory.audit(nil, current_membership, "Member canceled", self, Settings.operation_types.cancel)
      marketing_tool_sync_unsubscription
    end

    def propagate_membership_data
      self.current_membership.update_attribute :status, status
    end

    def set_decline_strategy(trans)
      # soft / hard decline
      tom = terms_of_membership
      decline = DeclineStrategy.find_by(gateway: trans.gateway.downcase, response_code: trans.response_code, credit_card_type: trans.cc_type) || 
                DeclineStrategy.find_by(gateway: trans.gateway.downcase, response_code: trans.response_code, 
                                     credit_card_type: "all")
      cancel_member = false
      if decline.nil?
        # we must send an email notifying about this error. Then schedule this job to run in the future (1 month)
        message = "Billing error. No decline rule configured: #{trans.response_code} #{trans.gateway}: #{trans.response_result}"
        operation_type = Settings.operation_types.membership_billing_without_decline_strategy
        self.next_retry_bill_date = Time.zone.now + eval(Settings.next_retry_on_missing_decline)
        self.save(validate: false)
        Auditory.notify_pivotal_tracker("Decline rule not found. User ##{self.id}", 
                                        "We have scheduled this billing to run again in #{Settings.next_retry_on_missing_decline} days.", 
                                        {'Member ID' => self.id, 'Transaction ID' => trans.id, 'Message' => message, 'CC type' => trans.cc_type})
          
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

      self.save(validate: false)
      Auditory.audit(nil, trans, message, self, operation_type )
      if cancel_member
        if tom.downgradable?
          downgrade_user
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
        self.fulfillments.where_bad_address.each do |fulfillment| 
          fulfillment.update_status( nil, 'not_processed', "Recovered from member unseted wrong address" )
        end
      end
    end

    def after_marketing_tool_sync
      self.lapsed? ? marketing_tool_sync_unsubscription : marketing_tool_sync
    end

    def set_marketing_client_sync_as_needed
      self.need_sync_to_marketing_client = true if (defined?(SacExactTarget::MemberModel) or defined?(SacMailchimp::MemberModel))
    end
    
    def days_until_next_bill_date
      @days_until_nbd ||= if (self.recycled_times == 0 and next_retry_bill_date > Time.zone.now) 
        (self.next_retry_bill_date.to_date - Time.zone.now.to_date).to_f
      else
        0
      end
      @days_until_nbd
    end

    def installment_amount_not_used
      if self.active?
        ((terms_of_membership.installment_amount.to_f*(days_until_next_bill_date/terms_of_membership.installment_period.to_f))*100).round / 100.0
      else
        0.0
      end
    end

    def club_cash_not_used(first_sale = false)
      club_cash = if first_sale and terms_of_membership.skip_first_club_cash
        0.0
      else
        (terms_of_membership.club_cash_installment_amount*(days_until_next_bill_date/terms_of_membership.installment_period.to_f)).round
      end
    end

    def mkt_tool_check_email_changed_for_sync
      if self.email_changed?
        if club.mailchimp_mandrill_client?
          Mailchimp::UserUpdateEmailJob.perform_later(self.id, self.email_change.first) if defined?(SacMailchimp::MemberModel)
        end
      end
    end

    def create_operation_on_testing_account_toggle
      if testing_account_was != testing_account
        if testing_account
          operation_type = Settings.operation_types.testing_account_marked
          message = I18n.t('activerecord.attributes.user.testing_account_marked')
        else
          operation_type = Settings.operation_types.testing_account_unmarked
          message = I18n.t('activerecord.attributes.user.testing_account_unmarked')
        end
        current_agent = RequestStore.store[:current_agent]
        Auditory.audit(current_agent, self, message, self, operation_type)
      end
    end

    def apply_downcase_to_email
      self.email = self.email.to_s.downcase if email_changed?
    end

    def slug_candidate
      [ (Digest::MD5.hexdigest(self.email) + self.club_id.to_s) ]
    end
    
    def prepend_zeros_to_phone_number
      self.phone_area_code    = format('%03d', phone_area_code.to_i)
      self.phone_local_number = format('%07d', phone_local_number.to_i)
    end
    
    def check_if_vip_member_allowed
      if member_group_type_id_changed?
        member_group_type = member_group_type_id_change.last ? MemberGroupType.find(member_group_type_id_change.last) : nil
        if member_group_type && member_group_type.name == 'VIP' && terms_of_membership.freemium?
          errors.add(:classification, 'Cannot set as VIP Member when user is associated to Freemium Membership.')
          return false
        end
      end
    end
    
    def update_club_cash_if_vip_member
      if member_group_type_id_changed? && !club_cash_amount_changed?
        old_member_group_type = member_group_type_id_change.first ? MemberGroupType.find(member_group_type_id_change.first) : nil
        new_member_group_type = member_group_type_id_change.last ? MemberGroupType.find(member_group_type_id_change.last) : nil
        if new_member_group_type&.name == 'VIP'
          add_club_cash(nil, Settings.vip_additional_club_cash, 'Marked user VIP Member.')
        elsif club_cash_amount > 0 && ((new_member_group_type.nil? || member_group_type&.name != 'VIP') && old_member_group_type&.name == 'VIP')
          add_club_cash(nil, -Settings.vip_additional_club_cash, 'Unmarked as VIP Member.')
        end
      end
    end
end
