# encoding: utf-8
class Member < ActiveRecord::Base
  include Extensions::UUID
  extend Extensions::Member::CountrySpecificValidations

  has_paper_trail :only => [:join_date, :cancel_date, :status]

  belongs_to :terms_of_membership
  belongs_to :club
  belongs_to :created_by, :class_name => 'Agent', :foreign_key => 'created_by_id'
  belongs_to :member_group_type
  has_many :member_notes
  has_many :credit_cards
  has_many :transactions
  has_many :operations
  has_many :communications
  has_many :fulfillments
  has_many :club_cash_transactions
  has_many :enrollment_infos, :order => "created_at DESC"
  has_many :member_preferences

  attr_accessible :address, :bill_date, :city, :country, :created_by, :description, 
      :email, :external_id, :first_name, :phone_country_code, :phone_area_code, :phone_local_number, 
      :join_date, :last_name, :status, :cancel_date, :next_retry_bill_date, 
      :bill_date, :quota, :state, :zip, :member_group_type_id, :blacklisted, :wrong_address,
      :wrong_phone_number, :credit_cards_attributes, :birth_date,
      :gender, :type_of_phone_number, :preferences

  # accepts_nested_attributes_for :credit_cards, :limit => 1

  serialize :preferences, JSON

  before_create :record_date
  before_save :wrong_address_logic

  after_create :after_create_sync_remote_domain
  after_update :after_update_sync_remote_domain
  after_destroy 'api_member.destroy! unless @skip_api_sync || api_member.nil? || api_id.nil?'
  after_create 'asyn_desnormalize_preferences(force: true)'
  after_update :asyn_desnormalize_preferences
  
  def after_create_sync_remote_domain
    api_member.save! unless @skip_api_sync || api_member.nil?
  rescue Exception => e
    # refs #21133
    # If there is connectivity problems or data errors with drupal. Do not stop enrollment!! 
    # Because maybe we have already bill this member.
    Airbrake.notify(:error_class => "Member:enroll", :error_message => e)
  end
  def after_update_sync_remote_domain
    api_member.save! unless @skip_api_sync || api_member.nil?
  end

  validates :country, 
    presence:                    true, 
    length:                      { is: 2, allow_nil: true },
    inclusion:                   { within: self.supported_countries }
  country_specific_validations!

  scope :synced, lambda { |bool=true|
    bool ?
      where('last_synced_at IS NOT NULL AND last_synced_at >= updated_at') :
      where('last_synced_at IS NULL OR last_synced_at < updated_at')
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
      where('last_sync_error_at IS NOT NULL')
    when 'noerror'
      where('last_sync_error_at IS NULL')
    end
  }
  scope :with_next_retry_bill_date, lambda { |value| where('next_retry_bill_date BETWEEN ? AND ?', value.to_date.to_time_in_current_zone.beginning_of_day, value.to_date.to_time_in_current_zone.end_of_day) unless value.blank? }
  scope :with_phone_country_code, lambda { |value| where('phone_country_code = ?', value) unless value.blank? }
  scope :with_phone_area_code, lambda { |value| where('phone_area_code like ?', value) unless value.blank? }
  scope :with_phone_local_number, lambda { |value| where('phone_local_number like ?', value) unless value.blank? }
  scope :with_visible_id, lambda { |value| where('visible_id = ?',value) unless value.blank? }
  scope :with_first_name_like, lambda { |value| where('first_name like ?', '%'+value+'%') unless value.blank? }
  scope :with_last_name_like, lambda { |value| where('last_name like ?', '%'+value+'%') unless value.blank? }
  scope :with_address_like, lambda { |value| where('address like ?', '%'+value+'%') unless value.blank? }
  scope :with_city_like, lambda { |value| where('city like ?', '%'+value+'%') unless value.blank? }
  scope :with_state_like, lambda { |value| where('state like ?', '%'+value+'%') unless value.blank? }
  scope :with_zip, lambda { |value| where('zip = ?', value) unless value.blank? }
  scope :with_email_like, lambda { |value| where('email like ?', '%'+value+'%') unless value.blank? }
  scope :with_credit_card_last_digits, lambda{ |value| joins(:credit_cards).where('last_digits = ?', value) unless value.blank? }
  scope :with_member_notes, lambda{ |value| joins(:member_notes).where('description like ?', '%'+value+'%') unless value.blank? }
  scope :with_external_id, lambda{ |value| where("external_id = ?",value) unless value.blank? }
  scope :needs_approval, lambda{ |value| where('status = ?', 'applied') unless value == '0' }

  state_machine :status, :initial => :none, :action => :save_state do
    after_transition [ :none, # enroll
                       :provisional, # save the sale
                       :lapsed, # reactivation
                       :active # save the sale
                    ] => :provisional, :do => :schedule_first_membership
    after_transition :none => :applied, :do => [:set_join_date, :send_active_needs_approval_email]
    after_transition [:provisional, :active] => :lapsed, :do => [:cancellation, :nillify_club_cash]
    after_transition :provisional => :active, :do => :send_active_email
    after_transition :lapsed => [:provisional, :applied], :do => :increment_reactivations
    after_transition :lapsed => :applied, :do => [ :set_join_date, :send_recover_needs_approval_email ]
    after_transition :applied => :provisional, :do => :schedule_first_membership_for_approved_member

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
      transition [:lapsed, :none] => :applied
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

  # Sets join date. It is called when members status is changed from 'none' to 'applied'
  def set_join_date
    self.join_date = Time.zone.now
    self.cohort = Member.cohort_formula(self.join_date, self.enrollment_infos.first, self.club.time_zone, self.terms_of_membership.installment_type)
    self.save
  end

  # Sends the fulfillment, and it settes bill_date and next_retry_bill_date according to member's terms of membership.
  def schedule_first_membership
    send_fulfillment
    self.bill_date = Time.zone.now + terms_of_membership.provisional_days
    self.next_retry_bill_date = bill_date
    # Documentation #18928 - recoveries will not change the quota number.
    if reactivation_times == 0
      self.quota = (terms_of_membership.monthly? ? 1 :  0)
    end
    self.join_date = Time.zone.now
    self.cohort = Member.cohort_formula(self.join_date, self.enrollment_infos.first, self.club.time_zone, self.terms_of_membership.installment_type)
    self.cancel_date = nil
    self.save
  end

  # Sends the fulfillment, and it settes bill_date and next_retry_bill_date according to member's terms of membership.  
  def schedule_first_membership_for_approved_member
    send_fulfillment
    self.bill_date = Time.zone.now + terms_of_membership.provisional_days
    self.next_retry_bill_date = bill_date
    if reactivation_times == 0
      self.quota = (terms_of_membership.monthly? ? 1 :  0)
    end
    self.cancel_date = nil
    self.save
  end

  # Changes next bill date.
  def change_next_bill_date!(next_bill_date)
    self.next_retry_bill_date = next_bill_date
    self.bill_date = next_bill_date
    self.save!
  end

  # Returns a string with first and last name concatenated. 
  def full_name
    [ first_name, last_name].join(' ').squeeze
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

  # Returns true if member is active or provisional.
  def can_bill_membership?
    self.active? or self.provisional?
  end

  # Returns true if member is lapsed or if it didnt reach the max reactivation times.
  def can_recover?
  # Add logic to recover some one max 3 times in 5 years
    self.lapsed? and reactivation_times < Settings.max_reactivations
  end

  # Do we need rules on fulfillment renewal?
  # Add logic here!!!
  def can_receive_another_fulfillment?
    (self.active? or self.provisional?) and membership_billed_recently?
  end
  ###############################################

  def save_the_sale(new_tom_id, agent = nil)
    if can_save_the_sale?
      if new_tom_id.to_i == self.terms_of_membership_id.to_i
        { :message => "Nothing to change. Member is already enrolled on that TOM.", :code => Settings.error_codes.nothing_to_change_tom }
      else
        old_tom_id = self.terms_of_membership_id
        self.terms_of_membership_id = new_tom_id
        res = enroll(self.active_credit_card, 0.0, agent, false, 0, self.enrollment_infos.first)
        if res[:code] == Settings.error_codes.success
          Auditory.audit(agent, TermsOfMembership.find(new_tom_id), 
            "Save the sale from TOMID #{old_tom_id} to TOMID #{new_tom_id}", self, Settings.operation_types.save_the_sale)
        end
        res
      end
    else
      { :message => "Member status does not allows us to save the sale.", :code => Settings.error_codes.member_status_dont_allow }
    end
  end

  # Recovers the member. Changes status from lapsed to applied or provisional (according to members term of membership.)
  def recover(new_tom_id, agent = nil)
    self.terms_of_membership_id = new_tom_id
    enroll(self.active_credit_card, 0.0, agent)
  end

  def bill_membership
    if can_bill_membership?
      amount = self.terms_of_membership.installment_amount
      if amount.to_f > 0.0
        # Grace period
        # why cero times? Because only 1 time must be Billed.
        # Before we were using times = 1. Problem is that times = 1, on case logic will allow times values [0,1].
        # So grace period will be granted twice.
        #        limit = 0 
        #        days  = campaign.grace_period
        if active_credit_card.nil?
          if terms_of_membership.grace_period > 0
            { :code => Settings.error_codes.credit_card_blank_with_grace, 
              :message => "Credit card is blank. Allowing grace period" }
          else
            { :code => Settings.error_codes.credit_card_blank_without_grace,
              :message => "Credit card is blank and grace period is disabled" }
          end
        else
          if terms_of_membership.payment_gateway_configuration.nil?
            message = "TOM ##{terms_of_membership.id} does not have a gateway configured."
            Auditory.audit(nil, terms_of_membership, message, self, Settings.operation_types.membership_billing_without_pgc)
            Airbrake.notify(:error_class => "Billing", :error_message => message)
            { :code => Settings.error_codes.tom_wihtout_gateway_configured, :message => message }
          else
            acc = CreditCard.recycle_expired_rule(active_credit_card, recycled_times)
            trans = Transaction.new
            trans.transaction_type = "sale"
            trans.prepare(self, acc, amount, self.terms_of_membership.payment_gateway_configuration)
            answer = trans.process
            if trans.success?
              assign_club_cash!
              set_as_active!
              schedule_renewal
              message = "Member billed successfully $#{amount} Transaction id: #{trans.id}"
              Auditory.audit(nil, trans, message, self, Settings.operation_types.membership_billing)
              { :message => message, :code => Settings.error_codes.success, :member_id => self.id }
            else
              message = set_decline_strategy(trans)
              answer # TODO: should we answer set_decline_strategy message too?
            end
          end
        end
      else
        { :message => "Called billing method but no amount on TOM is set.", :code => Settings.error_codes.no_amount }
      end
    else
      { :message => "Member is not in a billing status.", :code => Settings.error_codes.member_status_dont_allow }
    end
  end

  def error_to_s(delimiter = "\n")
    self.errors.collect {|attr, message| "#{attr}: #{message}" }.join(delimiter)
  end

  def self.enroll(tom, current_agent, enrollment_amount, member_params, credit_card_params, cc_blank = '0')
    credit_card_params = {} if credit_card_params.blank? # might be [], we expect a Hash
    club = tom.club
    member = Member.find_by_email_and_club_id(member_params[:email], club.id)
    if member.nil?
      # credit card exist?
      credit_card_params[:number].gsub!(' ', '') # HOT FIX on 
      credit_card = CreditCard.new credit_card_params
      credit_cards = CreditCard.joins(:member).where( :encrypted_number => credit_card.encrypted_number, :members => { :club_id => club.id } )

      if credit_cards.empty? or cc_blank == '1'
        member = Member.new
        member.update_member_data_by_params member_params
        member.skip_api_sync! if member.api_id.present? 
        member.club = club
        member.created_by_id = current_agent.id
        member.terms_of_membership = tom

        unless member.valid? and credit_card.valid?
          # errors = member.error_to_s + credit_card.error_to_s
          errors = member.errors.to_hash
          errors.merge!(credit_card: credit_card.errors.to_hash) unless credit_card.errors.empty?
          return { :message => "Member data is invalid.", :code => Settings.error_codes.member_data_invalid, 
                   :errors => errors }
        end
        # enroll allowed
      elsif not credit_cards.select { |cc| cc.blacklisted? }.empty? # credit card is blacklisted
        message = "That credit card is blacklisted, please use another."
        Auditory.audit(current_agent, tom, message, credit_cards.first.member, Settings.operation_types.credit_card_blacklisted)
        return { :message => message, :code => Settings.error_codes.credit_card_blacklisted }
      elsif not (cc_blank == '1' or credit_card_params[:number].blank?)
        message = "Credit card is already in use. call support."
        Auditory.audit(current_agent, tom, message, credit_cards.first.member, Settings.operation_types.credit_card_already_in_use)
        return { :message => message, :code => Settings.error_codes.credit_card_in_use }
      end
    else
      # TODO: should we update member profile? and Credit card information?
      if member.blacklisted
        message = "Member email is blacklisted."
        Auditory.audit(current_agent, tom, message, member, Settings.operation_types.member_email_blacklisted)
        return { :message => message, :code => Settings.error_codes.member_email_blacklisted }
      end
      credit_card = CreditCard.new credit_card_params
      member.update_member_data_by_params member_params
    end

    if cc_blank == '0' and credit_card_params[:number].blank?
      message = "Credit card is blank. Insert number or allow credit card blank."
      return { :message => message, :code => Settings.error_codes.credit_card_blank }        
    end   

    member.terms_of_membership = tom
    member.enroll(credit_card, enrollment_amount, current_agent, true, cc_blank, member_params)
  end

  def self.cohort_formula(join_date, enrollment_info, time_zone, installment_type)
    [ join_date.in_time_zone(time_zone).year.to_s, 
      "%02d" % join_date.in_time_zone(time_zone).month.to_s, 
      enrollment_info.mega_channel.to_s.strip, 
      enrollment_info.campaign_medium.to_s.strip,
      installment_type ].join('-').downcase
  end

  def enroll(credit_card, amount, agent = nil, recovery_check = true, cc_blank = 0, member_params = nil)
    amount.to_f == 0 and cc_blank == '1' ? allow_cc_blank = true : allow_cc_blank = false
    if recovery_check and not self.new_record? and not self.can_recover?
      return { :message => "Cant recover member. Max reactivations reached.", :code => Settings.error_codes.cant_recover_member }
    elsif not CreditCard.am_card(credit_card.number, credit_card.expire_month, credit_card.expire_year, first_name, last_name).valid?
        return { :message => "Credit card is invalid or is expired!", :code => Settings.error_codes.invalid_credit_card } if not allow_cc_blank
    elsif credit_card.blacklisted? or self.blacklisted?
      return { :message => "Member or credit card are blacklisted", :code => Settings.error_codes.blacklisted }
    elsif not self.valid? 
      return { :message => "Member data is invalid: \n#{error_to_s}", :code => Settings.error_codes.member_data_invalid }
    end
        
    enrollment_info = EnrollmentInfo.new :enrollment_amount => amount, :terms_of_membership_id => self.terms_of_membership_id
    enrollment_info.update_enrollment_info_by_hash member_params

    if amount.to_f != 0.0
      trans = Transaction.new
      trans.transaction_type = "sale"
      trans.prepare(self, credit_card, amount, self.terms_of_membership.payment_gateway_configuration)
      answer = trans.process
      unless trans.success?
        Auditory.audit(agent, self, "Transaction was not succesful.", self, answer.code)
        return answer 
      end
    end
    
    begin
      self.credit_cards << credit_card
      self.enrollment_infos << enrollment_info
      self.save!

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

      { :message => message, :code => Settings.error_codes.success, :member_id => self.id, :v_id => self.visible_id }
    rescue Exception => e
      Airbrake.notify(:error_class => "Member:enroll -- member turned invalid", :error_message => e)
      # TODO: this can happend if in the same time a new member is enrolled that makes this an invalid one. Do we have to revert transaction?
      message = "Could not save member. #{e}"
      Auditory.audit(agent, self, message, nil, Settings.operation_types.error_on_enrollment_billing)
      { :message => message, :code => Settings.error_codes.member_not_saved }
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
      fulfillments.each do |product|
        f = Fulfillment.new :product_sku => product
        f.member_id = self.uuid
        f.recurrent = Product.find_by_sku_and_club_id(product,self.club_id).recurrent rescue false
        f.save
        f.decrease_stock!
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
    self.last_synced_at && self.last_synced_at >= self.updated_at
  end

  def sync_status
    if self.last_sync_error_at
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

    if d 
      URI.parse(d.url) + self.autologin_url
    else
      nil
    end
  end

  ##################### Club cash ####################################

  # Resets member club cash in case of a cancelation.
  def nillify_club_cash
    add_club_cash(nil, -club_cash_amount.to_i, 'Removing club cash because of member cancellation')
    self.club_cash_expire_date = nil
    self.save(:validate => false)
  end

  # Resets member club cash in case the club cash has expired.
  def reset_club_cash
    add_club_cash(nil, -club_cash_amount.to_i, 'Removing expired club cash.')
    self.club_cash_expire_date = self.club_cash_expire_date + 12.months
    self.save(:validate => false)
  end

  # Adds club cash when membership billing is success.
  def assign_club_cash!(message = "Adding club cash after billing")
    amount = (self.member_group_type_id ? Settings.club_cash_for_members_who_belongs_to_group : terms_of_membership.club_cash_amount)
    self.add_club_cash(nil, amount, message)
    if self.club_cash_expire_date.nil? # first club cash assignment
      self.club_cash_expire_date = self.join_date + 1.year
    end
    self.save(:validate => false)
  end
  
  # Adds club cash transaction. 
  def add_club_cash(agent, amount = 0,description = nil)
    answer = { :code => Settings.error_codes.club_cash_transaction_not_successful  }
    if amount.to_i == 0
      answer[:message] = "Can not process club cash transaction with amount 0, values with commas, or letters."
    elsif (amount.to_i < 0 and amount.to_i.abs <= self.club_cash_amount.to_i) or amount.to_i > 0
      ClubCashTransaction.transaction do 
        begin
          cct = ClubCashTransaction.new(:amount => amount, :description => description)
          cct.member = self
          if cct.valid? 
            cct.save!
            self.club_cash_amount = self.club_cash_amount + amount.to_i
            self.save(:validate => false)
            message = "#{cct.amount.to_i.abs} club cash was successfully #{ amount.to_i >= 0 ? 'added' : 'deducted' }"
            if amount.to_i > 0
              Auditory.audit(agent, cct, message, self, Settings.operation_types.add_club_cash)
            elsif amount.to_i < 0 and amount.to_i.abs == club_cash_amount 
              Auditory.audit(agent, cct, message, self, Settings.operation_types.reset_club_cash)
            elsif amount.to_i < 0 
              Auditory.audit(agent, cct, message, self, Settings.operation_types.deducted_club_cash)
            end
            answer = { :message => message, :code => Settings.error_codes.success }
          else
            answer[:message] = "Could not save club cash transaction: #{cct.error_to_s} #{self.error_to_s}"
          end
        rescue Exception => e
          answer[:message] = "Could not save club cash transaction: #{cct.error_to_s} #{self.error_to_s}"
          Airbrake.notify(:error_class => 'Club cash Transaction', :error_message => e.to_s + answer[:message])
          raise ActiveRecord::Rollback
        end
      end
    else
      answer[:message] = "You can not deduct #{amount.to_i.abs} because the member only has #{self.club_cash_amount} club cash."
    end
    answer
  end

  def blacklist(agent, reason)
    if self.blacklisted?
      { :message => "Member already blacklisted!", :success => false }
    else
      self.blacklisted = true
      self.save(:validate => false)
      message = "Blacklisted member and all its credit cards. Reason: #{reason}."
      Auditory.audit(agent, self, message, self, Settings.operation_types.blacklisted)
      self.cancel! Time.zone.now, "Automatic cancellation"
      self.credit_cards.each { |cc| cc.blacklist }
      { :message => message, :success => true }
    end
  rescue Exception => e
    Airbrake.notify(:error_class => "Member::blacklist", :error_message => e)
    { :message => "Could not blacklisted this member.", :success => false }
  end
  ###################################################################

  def update_member_data_by_params(params)
    self.first_name = params[:first_name]
    self.last_name = params[:last_name]
    self.address = params[:address]
    self.state = params[:state]
    self.city = params[:city]
    self.country = params[:country]
    self.zip = params[:zip]
    self.email = params[:email]
    self.birth_date = params[:birth_date]
    self.joint = params[:joint]
    self.gender = params[:gender]
    self.type_of_phone_number = params[:type_of_phone_number]
    self.phone_country_code = params[:phone_country_code]
    self.phone_area_code = params[:phone_area_code]
    self.phone_local_number = params[:phone_local_number]
    self.preferences = params[:preferences]
    self.external_id = params[:external_id] if params[:external_id]
  end

  def chargeback!(transaction_chargebacked, args)
    trans = Transaction.new_chargeback(transaction_chargebacked, args)
    self.blacklist nil, args[:reason]
    self.cancel! Time.zone.now, "Automatic cancellation because of a chargeback."
    self.set_as_canceled!
  end

  def cancel!(cancel_date, message, current_agent = nil)
    if can_be_canceled?
      self.cancel_date = cancel_date
      self.save(:validate => false)
      Auditory.audit(current_agent, self, message, self, Settings.operation_types.future_cancel)
    end
  end
  
  def set_wrong_address(agent, reason)
    if self.wrong_address.nil?
      if self.update_attribute(:wrong_address, reason)
        self.fulfillments.where_processing.each { |s| s.set_as_undeliverable }
        message = "Address #{self.full_address} is undeliverable. Reason: #{reason}"
        Auditory.audit(agent,self,message,self)
        { :message => message, :code => Settings.error_codes.success }
      else
        message = "Could not set member's address as undeliverable. #{self.errors.inspect}"
        {:message => message, :code => Settings.error_codes.member_set_wrong_address_error}
      end
    else
      message = "Member's address already set as wrong address."
      { :message => message, :code => Settings.error_codes.member_already_set_wrong_address }
    end
  end

  private
    # TODO: finish this logic
    def membership_billed_recently?
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

      # cohort is set on status change
      info.update_attribute(:cohort, self.cohort)
      trans.update_attribute(:cohort, self.cohort) unless trans.nil?

      message = "Member #{description} successfully $#{amount} on TOM(#{terms_of_membership_id}) -#{terms_of_membership.name}-"
      Auditory.audit(agent, 
        (trans.nil? ? terms_of_membership : trans), 
        message, self, operation_type)
      message
    end

    def fulfillments_products_to_send
      self.enrollment_infos.first.product_sku ? self.enrollment_infos.first.product_sku.split(',') : []
    end

    def record_date
      self.member_since_date = Time.zone.now
    end

    def schedule_renewal
      new_bill_date = self.bill_date + eval(terms_of_membership.installment_type)
      if terms_of_membership.monthly?
        self.quota = self.quota + 1
        if self.recycled_times > 1
          new_bill_date = Time.zone.now + eval(terms_of_membership.installment_type)
        end
      elsif terms_of_membership.yearly?
        # refs #15935
        self.quota = self.quota + 12
      end
      self.recycled_times = 0
      self.bill_date = new_bill_date
      self.next_retry_bill_date = new_bill_date
      self.save
      Auditory.audit(nil, self, "Renewal scheduled. NBD set #{new_bill_date}", self)
    end

    def cancellation
      self.next_retry_bill_date = nil
      self.bill_date = nil
      self.recycled_times = 0
      Communication.deliver!(:cancellation, self)
      self.fulfillments.where_cancellable.each &:set_as_canceled
      # TODO: Deactivate drupal account
      self.save
      Auditory.audit(nil, self, "Member canceled", self, Settings.operation_types.cancel)
    end

    def set_decline_strategy(trans)
      # soft / hard decline
      type = self.terms_of_membership.installment_type
      decline = DeclineStrategy.find_by_gateway_and_response_code_and_installment_type_and_credit_card_type(trans.gateway.downcase, 
                  trans.response_code, type, trans.credit_card_type) || 
                DeclineStrategy.find_by_gateway_and_response_code_and_installment_type_and_credit_card_type(trans.gateway.downcase, 
                  trans.response_code, type, "all")
      cancel_member = false

      if decline.nil?
        # we must send an email notifying about this error. Then schedule this job to run in the future (1 month)
        message = "Billing error but no decline rule configured: #{trans.response_code} #{trans.gateway}: #{trans.response}"
        self.next_retry_bill_date = Time.zone.now + eval(Settings.next_retry_on_missing_decline)
        self.save
        unless trans.response_code == Settings.error_codes.invalid_credit_card 
          Airbrake.notify(:error_class => "Decline rule not found TOM ##{terms_of_membership.id}", 
            :error_message => "MID ##{self.id} TID ##{trans.id}. Message: #{message}. CC type: #{trans.credit_card_type}. " + 
                "Campaign type: #{type}. We have scheduled this billing to run again in #{Settings.next_retry_on_missing_decline} days.")
        end
        Auditory.audit(nil, trans, message, self, Settings.operation_types.membership_billing_without_decline_strategy)
        cancel_member = true if self.recycled_times >= Settings.number_of_retries_on_missing_decline
      else
        trans.update_attribute :decline_strategy_id, decline.id
        if decline.hard_decline?
          message = "Hard Declined: #{trans.response_code} #{trans.gateway}: #{trans.response_result}"
          cancel_member = true
        else
          message="Soft Declined: #{trans.response_code} #{trans.gateway}: #{trans.response_result}"
          if trans.response_code == Settings.error_codes.credit_card_blank_with_grace
            self.next_retry_bill_date = terms_of_membership.grace_period.to_i.days.from_now
          else
            self.next_retry_bill_date = decline.days.days.from_now
          end
          if self.recycled_times > (decline.limit-1)
            message = "Soft recycle limit (#{self.recycled_times}) reached: #{trans.response_code} #{trans.gateway}: #{trans.response_result}"
            cancel_member = true
          end
        end
      end
      if cancel_member
        Auditory.audit(nil, trans, message, self, Settings.operation_types.membership_billing_hard_decline)
        set_as_canceled!
      else
        Auditory.audit(nil, trans, message, self, Settings.operation_types.membership_billing_soft_decline)
        increment(:recycled_times, 1)
      end
      message
    end

    def asyn_desnormalize_preferences(opts = {})
      self.desnormalize_preferences if opts[:force] || self.changed.include?('preferences') 
    end

    def wrong_address_logic
      if self.changed.include?('wrong_address') and self.wrong_address.nil?
        self.fulfillments.where_undeliverable.each { |s| s.decrease_stock! }
      end
    end

  public 
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

end
