# encoding: utf-8
class Member < ActiveRecord::Base
  include Extensions::UUID
  extend Extensions::Member::CountrySpecificValidations

  belongs_to :club
  belongs_to :member_group_type
  has_many :member_notes
  has_many :credit_cards
  has_many :transactions
  has_many :operations
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
    if can_be_synced_to_remote? # Bug #23017 - skip sync if lapsed or applied.
      unless @skip_api_sync || api_member.nil?
        time_elapsed = Benchmark.ms do
          api_member.save!
        end
        logger.info "Drupal::sync took #{time_elapsed}ms"
      end
    end
    sync_to_pardot unless @skip_pardot_sync || pardot_member.nil?
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
  scope :with_next_retry_bill_date, lambda { |value| where('next_retry_bill_date BETWEEN ? AND ?', value.to_date.to_time_in_current_zone.beginning_of_day, value.to_date.to_time_in_current_zone.end_of_day) unless value.blank? }
  scope :with_phone_country_code, lambda { |value| where('phone_country_code = ?', value.strip) unless value.blank? }
  scope :with_phone_area_code, lambda { |value| where('phone_area_code = ?', value.strip) unless value.blank? }
  scope :with_phone_local_number, lambda { |value| where('phone_local_number = ?', value.strip) unless value.blank? }
  scope :with_visible_id, lambda { |value| where('visible_id = ?',value.strip) unless value.blank? }
  scope :with_first_name_like, lambda { |value| where('first_name like ?', '%'+value.strip+'%') unless value.blank? }
  scope :with_last_name_like, lambda { |value| where('last_name like ?', '%'+value.strip+'%') unless value.blank? }
  scope :with_address_like, lambda { |value| where('address like ?', '%'+value.strip+'%') unless value.blank? }
  scope :with_city_like, lambda { |value| where('city like ?', '%'+value.strip+'%') unless value.blank? }
  scope :with_state_like, lambda { |value| where('state like ?', '%'+value.strip+'%') unless value.blank? }
  scope :with_zip, lambda { |value| where('zip like ?', '%'+value.strip+'%') unless value.blank? }
  scope :with_email_like, lambda { |value| where('email like ?', '%'+value.strip+'%') unless value.blank? }
  scope :with_credit_card_last_digits, lambda{ |value| joins(:credit_cards).where('last_digits = ?', value.strip) unless value.blank? }
  scope :with_member_notes, lambda{ |value| joins(:member_notes).where('description like ?', '%'+value.strip+'%') unless value.blank? }
  scope :with_external_id, lambda{ |value| where("external_id = ?",value) unless value.blank? }
  scope :needs_approval, lambda{ |value| where('status = ?', 'applied') unless value == '0' }

  state_machine :status, :initial => :none, :action => :save_state do
    ###### member gets applied =====>>>>
    after_transition :lapsed => 
                        :applied, :do => [:set_join_date, :send_recover_needs_approval_email]
    after_transition [ :none, :provisional, :active ] => # none is new join. provisional and active are save the sale
                        :applied, :do => [:set_join_date, :send_active_needs_approval_email]
    ###### <<<<<<========
    ###### member gets provisional =====>>>>
    after_transition [ :none, :lapsed ] => # enroll and reactivation
                        :provisional, :do => :schedule_first_membership
    after_transition [ :provisional, :active ] => 
                        :provisional, :do => :schedule_first_membership # save the sale
    after_transition :applied => 
                        :provisional, :do => :schedule_first_membership_for_approved_member
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
    membership = current_membership
    membership.join_date = Time.zone.now
    membership.save
  end

  def set_member_as_rejected
    decrement!(:reactivation_times, 1) if reactivation_times > 0 # we increment when it gets applied. If we reject the member we have to get back
    self.current_membership.update_attribute(:cancel_date, Time.zone.now)
  end

  # Sends the fulfillment, and it settes bill_date and next_retry_bill_date according to member's terms of membership.
  def schedule_first_membership
    send_fulfillment
    membership = current_membership
    membership.join_date = Time.zone.now
    self.bill_date = Time.zone.now + terms_of_membership.provisional_days
    self.next_retry_bill_date = bill_date
    self.save
    membership.save
  end

  # Sends the fulfillment, and it settes bill_date and next_retry_bill_date according to member's terms of membership.  
  def schedule_first_membership_for_approved_member
    send_fulfillment
    self.bill_date = Time.zone.now + terms_of_membership.provisional_days
    self.next_retry_bill_date = bill_date
    self.save
    membership = current_membership
    membership.save
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

  def can_be_synced_to_remote?
    !(lapsed? or applied?)
  end

  # Returns true if members is lapsed.
  def can_be_canceled?
    !self.lapsed? and !self.cancel_date
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
    # TODO: Add logic to recover some one max 3 times in 5 years
    self.lapsed? and reactivation_times < Settings.max_reactivations
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
  ###############################################

  def save_the_sale(new_tom_id, agent = nil)
    if can_save_the_sale?
      if new_tom_id.to_i == terms_of_membership.id
        { :message => "Nothing to change. Member is already enrolled on that TOM.", :code => Settings.error_codes.nothing_to_change_tom }
      else
        old_tom_id = terms_of_membership.id
        prev_membership_id = current_membership.id
        res = enroll(TermsOfMembership.find(new_tom_id), self.active_credit_card, 0.0, agent, false, 0, self.current_membership.enrollment_info)
        if res[:code] == Settings.error_codes.success
          Auditory.audit(agent, TermsOfMembership.find(new_tom_id), 
            "Save the sale from TOMID #{old_tom_id} to TOMID #{new_tom_id}", self, Settings.operation_types.save_the_sale)
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
    enroll(new_tom, self.active_credit_card, 0.0, agent, true, 0, self.current_membership.enrollment_info)
  end

  def bill_membership
    if can_bill_membership?
      amount = terms_of_membership.installment_amount
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
        elsif terms_of_membership.payment_gateway_configuration.nil?
          message = "TOM ##{terms_of_membership.id} does not have a gateway configured."
          Auditory.audit(nil, terms_of_membership, message, self, Settings.operation_types.membership_billing_without_pgc)
          Airbrake.notify(:error_class => "Billing", :error_message => message, :parameters => { :member => self.inspect, :membership => current_membership })
          { :code => Settings.error_codes.tom_wihtout_gateway_configured, :message => message }
        else
          acc = CreditCard.recycle_expired_rule(active_credit_card, recycled_times)
          trans = Transaction.new
          trans.transaction_type = "sale"
          trans.prepare(self, acc, amount, terms_of_membership.payment_gateway_configuration)
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

  def self.enroll(tom, current_agent, enrollment_amount, member_params, credit_card_params, cc_blank = false, skip_api_sync = false)
    credit_card_params = {} if credit_card_params.blank? # might be [], we expect a Hash
    club = tom.club
    member = Member.find_by_email_and_club_id(member_params[:email], club.id)
    if member.nil?
      # credit card exist?
      credit_card_params[:number] .gsub!(' ', '') # HOT FIX on 
      credit_card = CreditCard.new credit_card_params
      credit_cards = CreditCard.joins(:member).where( :encrypted_number => credit_card.encrypted_number, :members => { :club_id => club.id } )

      if credit_cards.empty? or cc_blank
        member = Member.new
        member.update_member_data_by_params member_params
        member.skip_api_sync! if member.api_id.present? || skip_api_sync
        member.club = club
        unless member.valid? and credit_card.valid?
          errors = member.errors.to_hash
          errors.merge!(credit_card: credit_card.errors.to_hash) unless credit_card.errors.empty?
          return { :message => Settings.error_messages.member_data_invalid, :code => Settings.error_codes.member_data_invalid, 
                   :errors => errors }
        end
        # enroll allowed
      elsif not credit_cards.select { |cc| cc.blacklisted? }.empty? # credit card is blacklisted
        message = Settings.error_messages.credit_card_blacklisted
        Auditory.audit(current_agent, tom, message, credit_cards.first.member, Settings.operation_types.credit_card_blacklisted)
        return { :message => message, :code => Settings.error_codes.credit_card_blacklisted }
      elsif not (cc_blank or credit_card_params[:number].blank?)
        message = Settings.error_messages.credit_card_in_use
        Auditory.audit(current_agent, tom, message, credit_cards.first.member, Settings.operation_types.credit_card_in_use)
        return { :message => message, :code => Settings.error_codes.credit_card_in_use }
      end
    elsif member.blacklisted
      message = Settings.error_messages.member_email_blacklisted
      Auditory.audit(current_agent, tom, message, member, Settings.operation_types.member_email_blacklisted)
      return { :message => message, :code => Settings.error_codes.member_email_blacklisted }
    else
      credit_card = CreditCard.new credit_card_params
      member.update_member_data_by_params member_params
    end

    if not cc_blank and credit_card_params[:number].blank?
      message = Settings.error_messages.credit_card_blank
      return { :message => message, :code => Settings.error_codes.credit_card_blank }        
    end   

    member.enroll(tom, credit_card, enrollment_amount, current_agent, true, cc_blank, member_params)
  end

  def enroll(tom, credit_card, amount, agent = nil, recovery_check = true, cc_blank = false, member_params = nil)
    allow_cc_blank = (amount.to_f == 0.0 and cc_blank)
    if recovery_check and not self.new_record? and not self.can_recover?
      return { :message => Settings.error_messages.cant_recover_member, :code => Settings.error_codes.cant_recover_member }
    elsif not CreditCard.am_card(credit_card.number, credit_card.expire_month, credit_card.expire_year, first_name, last_name).valid?
        return { :message => Settings.error_messages.invalid_credit_card, :code => Settings.error_codes.invalid_credit_card } if not allow_cc_blank
    elsif credit_card.blacklisted? or self.blacklisted?
      return { :message => Settings.error_messages.blacklisted, :code => Settings.error_codes.blacklisted }
    elsif not self.valid? 
      errors = member.errors.to_hash
      errors.merge!(credit_card: credit_card.errors.to_hash) unless credit_card.errors.empty?
      return { :message => Settings.error_messages.member_data_invalid, :code => Settings.error_codes.member_data_invalid, 
               :errors => errors }
    end
        
    enrollment_info = EnrollmentInfo.new :enrollment_amount => amount, :terms_of_membership_id => tom.id
    enrollment_info.update_enrollment_info_by_hash member_params
    membership = Membership.new(terms_of_membership_id: tom.id, created_by: agent)
    self.current_membership = membership

    if amount.to_f != 0.0
      trans = Transaction.new
      trans.transaction_type = "sale"
      trans.prepare(self, credit_card, amount, tom.payment_gateway_configuration)
      answer = trans.process
      unless trans.success?
        Auditory.audit(agent, self, "Transaction was not succesful.", self, answer[:code])
        return answer 
      end
    end
    
    begin
      self.credit_cards << credit_card
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

      { :message => message, :code => Settings.error_codes.success, :member_id => self.id, :v_id => self.visible_id }
    rescue Exception => e
      Airbrake.notify(:error_class => "Member:enroll -- member turned invalid", :error_message => e, :parameters => { :member => self.inspect, :credit_card => credit_card, :enrollment_info => enrollment_info })
      # TODO: this can happend if in the same time a new member is enrolled that makes this an invalid one. Do we have to revert transaction?
      Auditory.audit(agent, self, e, nil, Settings.operation_types.error_on_enrollment_billing)
      { :message => message, :code => Settings.error_codes.member_not_saved }
    end
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

    if d 
      URI.parse(d.url) + self.autologin_url
    else
      nil
    end
  end

  ##################### Club cash ####################################

  # Resets member club cash in case of a cancelation.
  def nillify_club_cash
    add_club_cash(nil, -club_cash_amount, 'Removing club cash because of member cancellation')
    self.club_cash_expire_date = nil
    self.save(:validate => false)
  end

  # Resets member club cash in case the club cash has expired.
  def reset_club_cash
    add_club_cash(nil, -club_cash_amount, 'Removing expired club cash.')
    self.club_cash_expire_date = self.club_cash_expire_date + 12.months
    self.save(:validate => false)
  end

  # Adds club cash when membership billing is success.
  def assign_club_cash!(message = "Adding club cash after billing")
    amount = (self.member_group_type_id ? Settings.club_cash_for_members_who_belongs_to_group : terms_of_membership.club_cash_amount)
    self.add_club_cash(nil, amount, message)
    if self.club_cash_expire_date.nil? # first club cash assignment
      self.club_cash_expire_date = join_date + 1.year
    end
    self.save(:validate => false)
  end
  
  # Adds club cash transaction. 
  def add_club_cash(agent, amount = 0,description = nil)
    answer = { :code => Settings.error_codes.club_cash_transaction_not_successful  }
    if amount.to_f == 0
      answer[:message] = "Can not process club cash transaction with amount 0, values with commas, or letters."
    elsif (amount.to_f < 0 and amount.to_f.abs <= self.club_cash_amount) or amount.to_f > 0
      ClubCashTransaction.transaction do 
        cct = ClubCashTransaction.new(:amount => amount, :description => description)
        begin
          cct.member = self
          if cct.valid? 
            cct.save!
            self.club_cash_amount = self.club_cash_amount + amount.to_f
            self.save(:validate => false)
            message = "#{cct.amount.to_f.abs} club cash was successfully #{ amount.to_f >= 0 ? 'added' : 'deducted' }"
            if amount.to_f > 0
              Auditory.audit(agent, cct, message, self, Settings.operation_types.add_club_cash)
            elsif amount.to_f < 0 and amount.to_f.abs == club_cash_amount 
              Auditory.audit(agent, cct, message, self, Settings.operation_types.reset_club_cash)
            elsif amount.to_f < 0 
              Auditory.audit(agent, cct, message, self, Settings.operation_types.deducted_club_cash)
            end
            answer = { :message => message, :code => Settings.error_codes.success }
          else
            answer[:message] = "Could not save club cash transaction: #{cct.error_to_s} #{self.error_to_s}"
          end
        rescue Exception => e
          answer[:message] = "Could not save club cash transaction: #{cct.error_to_s} #{self.error_to_s}"
          Airbrake.notify(:error_class => 'Club cash Transaction', :error_message => e.to_s + answer[:message], :parameters => { :club_cash => cct.inspect, :member => self.inspect })
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
      self.set_as_canceled! unless self.lapsed?
      { :message => message, :success => true }
    end
  rescue Exception => e
    Airbrake.notify(:error_class => "Member::blacklist", :error_message => e, :parameters => { :member => self.inspect })
    { :message => "Could not blacklisted this member.", :success => false }
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
    self.blacklist nil, args[:reason]
    self.cancel! Time.zone.now, "Automatic cancellation because of a chargeback."
    self.set_as_canceled!
  end

  def cancel!(cancel_date, message, current_agent = nil)
    if can_be_canceled?
      self.current_membership.update_attribute :cancel_date, cancel_date
      Auditory.audit(current_agent, self, message, self, Settings.operation_types.future_cancel)
    end
  end
  
  def set_wrong_address(agent, reason)
    if self.wrong_address.nil?
      if self.update_attribute(:wrong_address, reason)
        self.fulfillments.where_processing.not_renewed.each { |s| s.set_as_undeliverable }
        self.fulfillments.where_not_processed.not_renewed.each { |s| s.set_as_undeliverable }
        message = "Address #{self.full_address} is undeliverable. Reason: #{reason}"
        Auditory.audit(agent, self, message, self)
        { :message => message, :code => Settings.error_codes.success }
      else
        message = "#{Settings.error_messages.member_set_wrong_address_error} #{self.errors.inspect}"
        {:message => message, :code => Settings.error_codes.member_set_wrong_address_error}
      end
    else
      message = Settings.error_messages.member_already_set_wrong_address
      { :message => message, :code => Settings.error_codes.member_already_set_wrong_address }
    end
  end


  private
    def schedule_renewal
      new_bill_date = self.bill_date + eval(terms_of_membership.installment_type)
      if terms_of_membership.monthly?
        self.current_membership.increment!(:quota)
        if self.recycled_times > 1
          new_bill_date = Time.zone.now + eval(terms_of_membership.installment_type)
        end
      elsif terms_of_membership.yearly?
        # refs #15935
        self.current_membership.increment!(:quota, 12)
      end
      self.recycled_times = 0
      self.bill_date = new_bill_date
      self.next_retry_bill_date = new_bill_date
      self.save
      Auditory.audit(nil, self, "Renewal scheduled. NBD set #{new_bill_date}", self)
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
      self.fulfillments.where_cancellable.each &:set_as_canceled
      self.next_retry_bill_date = nil
      self.bill_date = nil
      self.recycled_times = 0
      self.save
      Auditory.audit(nil, self, "Member canceled", self, Settings.operation_types.cancel)
    end

    def propagate_membership_data
      self.current_membership.update_attribute :status, status
    end

    def set_decline_strategy(trans)
      # soft / hard decline
      type = terms_of_membership.installment_type
      decline = DeclineStrategy.find_by_gateway_and_response_code_and_installment_type_and_credit_card_type(trans.gateway.downcase, 
                  trans.response_code, type, trans.credit_card_type) || 
                DeclineStrategy.find_by_gateway_and_response_code_and_installment_type_and_credit_card_type(trans.gateway.downcase, 
                  trans.response_code, type, "all")
      cancel_member = false

      if decline.nil?
        # we must send an email notifying about this error. Then schedule this job to run in the future (1 month)
        message = "Billing error. No decline rule configured: #{trans.response_code} #{trans.gateway}: #{trans.response_result}"
        self.next_retry_bill_date = Time.zone.now + eval(Settings.next_retry_on_missing_decline)
        self.save(:validate => false)
        unless trans.response_code == Settings.error_codes.invalid_credit_card 
          Airbrake.notify(:error_class => "Decline rule not found TOM ##{terms_of_membership.id}", 
            :error_message => "MID ##{self.id} TID ##{trans.id}. Message: #{message}. CC type: #{trans.credit_card_type}. " + 
              "Campaign type: #{type}. We have scheduled this billing to run again in #{Settings.next_retry_on_missing_decline} days.",
            :parameters => { :member => self.inspect })
        end
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
      self.save(:validate => false)
      if cancel_member
        Auditory.audit(nil, trans, message, self, Settings.operation_types.membership_billing_hard_decline)
        set_as_canceled!
      else
        Auditory.audit(nil, trans, message, self, Settings.operation_types.membership_billing_soft_decline)
        increment!(:recycled_times, 1)
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


    def update_credit_card_from_drupal(credit_card, current_agent = nil)
      return { :code => Settings.error_codes.success } if credit_card.nil? || credit_card.empty?
      new_year, new_month, new_number = credit_card[:expire_year], credit_card[:expire_month], nil

      # Drupal sends X when member does not change the credit card number      
      if credit_card[:number].include?('X')
        if active_credit_card.last_digits.to_s == credit_card[:number][-4..-1].to_s # lets update expire month
          active_credit_card.update_expire(new_year, new_month)
        else # do not update nothing, credit cards do not match or its expired
          { :code => Settings.error_codes.invalid_credit_card, :message => Settings.error_messages.invalid_credit_card, :errors => { :number => "Credit card do not match the active one." }}
        end
      else # drupal or CS sends the complete credit card number.
        new_credit_card = CreditCard.new(:number => credit_card[:number], :expire_month => new_month, :expire_year => new_year)
        credit_cards = CreditCard.joins(:member).where( [ " encrypted_number = ? and members.club_id = ? ", new_credit_card.encrypted_number, club.id ] )
        if credit_cards.empty?
          add_new_credit_card(new_credit_card, current_agent)
        elsif not credit_cards.select { |cc| cc.blacklisted? }.empty? # credit card is blacklisted
          { :message => Settings.error_messages.credit_card_blacklisted, :code => Settings.error_codes.credit_card_blacklisted, :errors => { :number => "Credit card is blacklisted" }}
        elsif not credit_cards.select { |cc| cc.member_id == self.id and cc.active }.empty? # is this credit card already of this member and its already active?
          active_credit_card.update_expire(new_year, new_month) # lets update expire month
        elsif not credit_cards.select { |cc| cc.member_id == self.id and not cc.active }.empty? and not credit_cards.select { |cc| cc.member_id != self.id and cc.active }.empty?
          # is this credit card already of this member but its inactive? and we found another credit card assigned to another member but in active status?
          { :message => Settings.error_messages.credit_card_in_use, :code => Settings.error_codes.credit_card_in_use, :errors => { :number => "Credit card is already in use" }}
        elsif not credit_cards.select { |cc| cc.member_id == self.id and not cc.active }.empty? and credit_cards.select { |cc| cc.member_id != self.id and cc.active }.empty?
          # is this credit card already of this member but its inactive? and we found another credit card assigned to another member but in active status?
          new_active_credit_card = CreditCard.find credit_cards.select { |cc| cc.member_id == self.id }.first.id
          answer = new_active_credit_card.update_expire(new_year, new_month) # lets update expire month
          if answer[:code] == Settings.error_codes.success
            # activate new credit card ONLY if expire date was updated.
            new_active_credit_card.set_as_active!
          end
          answer
        elsif credit_cards.select { |cc| cc.active }.empty? # its not my credit card. its from another member. the question is. can I use it?
          add_new_credit_card(new_credit_card, current_agent)
        else
          { :message => Settings.error_messages.credit_card_in_use, :code => Settings.error_codes.credit_card_in_use, :errors => { :number => "Credit card is already in use" }}
        end
      end
    end

    def add_new_credit_card(new_credit_card, current_agent = nil)
      answer = { :message => "There was an error. We could not add the credit card.", :code => Settings.error_codes.invalid_credit_card }
      CreditCard.transaction do 
        begin
          new_credit_card.member = self
          if new_credit_card.am_card.valid?
            new_credit_card.save!
            message = "Credit card #{new_credit_card.last_digits} added and activated."
            Auditory.audit(current_agent, new_credit_card, message, self)
            answer = { :code => Settings.error_codes.success, :message => message }
            new_credit_card.set_as_active!
          else
            answer = { :code => Settings.error_codes.invalid_credit_card, :message => Settings.error_messages.invalid_credit_card, :errors => new_credit_card.am_card.errors.to_hash }
          end        
        rescue Exception => e
          answer.merge!({:errors => e})
          Airbrake.notify(:error_class => "Member:update_credit_card", :error_message => e, :parameters => { :member => self.inspect, :credit_card => new_credit_card })
          logger.error e.inspect
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
        pardot_member.save!(options)
      end
      logger.info "Pardot::sync took #{time_elapsed}ms"
    rescue Exception => e
      Airbrake.notify(:error_class => "Pardot:sync", :error_message => e, :parameters => { :member => self.inspect })
    end
    # sync member in 10 minutes, why? lets allow prospect to be synced first.
    handle_asynchronously :sync_to_pardot, :run_at => Proc.new { 5.minutes.from_now }

end
