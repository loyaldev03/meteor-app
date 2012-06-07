class Member < ActiveRecord::Base
  include Extensions::UUID
  
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

  attr_accessible :address, :bill_date, :city, :country, :created_by, :description, 
      :email, :external_id, :first_name, :phone_number, 
      :join_date, :last_name, :status, :cancel_date, :next_retry_bill_date, 
      :bill_date, :quota, :state, :terms_of_membership_id, :zip, 
      :club_id, :partner_id, :member_group_type_id, :blacklisted, :wrong_address, :wrong_phone_number

  before_create :record_date
  after_save 'api_member.save!'
  after_destroy 'api_member.destroy!'

  validates :first_name, :presence => true, :format => /^[A-Za-z ']+$/
  validates :email, :presence => true, :uniqueness => { :scope => :club_id }, 
            :format => /^([0-9a-zA-Z]([-\.\w]*[+?]?[0-9a-zA-Z])*@([0-9a-zA-Z][-\w]*[0-9a-zA-Z]\.)+[a-zA-Z]{2,9})$/
  validates :last_name , :presence => true, :format => /^[A-Za-z ']+$/
  validates :phone_number, :format => /^(\([+]?([0-9]{1,3})\))?[-. ]?([0-9]{1,3})?[-. ]?([0-9]{2,3})[-. ]?([0-9]{2,4})?[-. ]?([0-9]{4})([-. ]\(?(x|int)?[0-9]?{1,10}\)?)?$/ 
  validates :address, :city, :state, :country, :presence => true, :format => /^[A-Za-z0-9 ',\s]+$/
  validates :terms_of_membership_id , :presence => true
  validates :zip, :presence => true, :format => /^[0-9]{5}(-?[0-9]{4})?$/

  scope :synced, lambda { |bool=true|
    bool ?
      base.where('last_synced_at > updated_at') :
      base.where('last_synced_at IS NULL OR last_synced_at < updated_at')
  }

  state_machine :status, :initial => :none do
    after_transition [:none, :provisional, :lapsed] => :provisional, :do => :schedule_first_membership
    after_transition [:provisional, :active] => :lapsed, :do => :cancellation
    after_transition [:provisional] => :active, :do => :send_active_email
    after_transition :lapsed => :any, :do => :increment_reactivations

    event :set_as_provisional do
      transition [:none, :provisional] => :provisional
    end
    event :set_as_active do
      transition [:provisional, :active] => :active
    end
    event :set_as_canceled do
      transition [:provisional, :active] => :lapsed
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
    # (ONLY IN NFLA PLAYER PROGRAM) When an Applied Member has been “approved” to join the NFLA, 
    # they are considered an approved member. (Approvals are done through NFLA and managed by Stoneacre)
    state :approved
  end

  def send_active_email
    Communication.deliver!(:active, self)
  end

  def increment_reactivations
    increment!(:reactivation_times, 1)
  end

  def schedule_first_membership
    send_fulfillment
    self.bill_date = Date.today + terms_of_membership.trial_days
    self.next_retry_bill_date = bill_date
    # Documentation #18928 - recoveries will not change the quota number.
    if reactivation_times == 0
      self.quota = (terms_of_membership.monthly? ? 1 :  0)
    end
    self.join_date = DateTime.now 
    self.cancel_date = nil
    self.save
  end

  def change_next_bill_date!(next_bill_date)
    self.next_retry_bill_date = next_bill_date
    self.bill_date = next_bill_date
    self.save!
  end

  def full_name
    [ first_name, last_name].join(' ')
  end

  def active_credit_card
    self.credit_cards.find_by_active(true)
  end

  def full_address
    [address, city, state].join(' ')
  end

  ####  METHODS USED TO SHOW OR NOT BUTTONS. 
  def can_be_canceled?
    !self.lapsed?
  end

  def can_save_the_sale?
    self.active? or self.provisional?
  end

  def can_bill_membership?
    self.active? or self.provisional?
  end

  # Add logic to recover some one max 3 times in 5 years
  def can_recover?
    self.lapsed? and reactivation_times <= Settings.max_reactivations
  end

  # Do we need rules on fulfillment renewal?
  # Add logic here!!!
  def can_receive_another_fulfillment?
    self.active? or self.provisional?
  end
  ###############################################

  def save_the_sale(new_tom_id, agent = nil)
    if can_save_the_sale?
      if new_tom_id.to_i == self.terms_of_membership_id.to_i
        { :message => "Nothing to change. Member is already enrolled on that TOM.", :code => Settings.error_codes.nothing_to_change_tom }
      else
        self.terms_of_membership_id = new_tom_id
        res = enroll(self.active_credit_card, 0.0, agent, false)
        if res[:code] == Settings.error_codes.success
          message = "Save the sale from TOMID #{self.terms_of_membership_id} to TOMID #{new_tom_id}"
          Auditory.audit(agent, self, message, TermsOfMembership.find(new_tom_id), Settings.operation_types.save_the_sale)
        end
        res
      end
    else
      { :message => "Member status does not allows us to save the sale.", :code => Settings.error_codes.member_status_dont_allow }
    end
  end

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
          answer = if terms_of_membership.grace_period > 0
            { :code => Settings.error_codes.credit_card_blank_with_grace, 
              :message => "Credit card is blank. Allowing grace period" }
          else
            { :code => Settings.error_codes.credit_card_blank_without_grace,
              :message => "Credit card is blank and grace period is disabled" }
          end
        else
          if terms_of_membership.payment_gateway_configuration.nil?
            message = "TOM ##{terms_of_membership.id} does not have a gateway configured."
            # TODO: do we have to add an operation?????
            Auditory.add_redmine_ticket("Billing", message)
            return { :code => Settings.error_codes.tom_wihtout_gateway_configured, :message => message }
          end
          acc = CreditCard.recycle_expired_rule(active_credit_card, recycled_times)
          trans = Transaction.new
          trans.transaction_type = "sale"
          trans.prepare(self, acc, amount, self.terms_of_membership.payment_gateway_configuration)
          answer = trans.process
          if trans.success?
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

  def self.enroll(tom, current_agent, enrollment_amount, member_params, credit_card_params)
    club = tom.club
    # Member exist?
    member = Member.find_by_email_and_club_id(member_params[:email], club.id)
    if member.nil?
      # credit card exist?
      credit_card_params[:number].gsub!(' ', '') # HOT FIX on 
      credit_card = CreditCard.find_all_by_number(credit_card_params[:number]).select { |cc| cc.member.club_id == club.id }
      if credit_card.empty?
        credit_card = CreditCard.new credit_card_params
        member = Member.new member_params
        member.club = club
        member.created_by_id = current_agent.id
        member.terms_of_membership = tom
        unless member.valid? and credit_card.valid?
          errors = member.errors.collect {|attr, message| "#{attr}: #{message}" }.join("\n") + 
                    credit_card.errors.collect {|attr, message| "#{attr}: #{message}" }.join("\n")
          return { :message => "Member data is invalid: #{errors}", :code => Settings.error_codes.member_data_invalid }
        end
        # enroll allowed
      elsif not credit_card.select { |cc| cc.blacklisted? }.empty? # credit card is blacklisted
        message = "Credit card blacklisted. call support."
        Auditory.audit(current_agent, tom, message, credit_card.first.member, Settings.operation_types.credit_card_blacklisted)
        return { :message => message, :code => Settings.error_codes.credit_card_blacklisted }
      else        
        message = "Credit card is already in use. call support."
        Auditory.audit(current_agent, tom, message, credit_card.first.member, Settings.operation_types.credit_card_already_in_use)
        return { :message => message, :code => Settings.error_codes.credit_card_in_use }
      end
    else
      # TODO: should we update member profile? and Credit card information?
      if member.blacklisted
        message = "Member email is blacklisted"
        Auditory.audit(current_agent, tom, message, member, Settings.operation_types.member_email_blacklisted)
        return { :message => message, :code => Settings.error_codes.member_email_blacklisted }
      end
      credit_card = CreditCard.new credit_card_params
    end
    
    member.terms_of_membership = tom
    member.enroll(credit_card, enrollment_amount, current_agent)
  end    

  def enroll(credit_card, amount, agent = nil, recovery_check = true)
    if not self.new_record? and recovery_check and not self.can_recover?
      return { :message => "Cant recover member. Actual status is not lapsed or Max reactivations reached.", :code => Settings.error_codes.cant_recover_member }
    elsif not CreditCard.am_card(credit_card.number, credit_card.expire_month, credit_card.expire_year, first_name, last_name).valid?
      return { :message => "Credit card is invalid or is expired!", :code => Settings.error_codes.invalid_credit_card }
    elsif credit_card.blacklisted? or self.blacklisted?
      return { :message => "Member or credit card are blacklisted", :code => Settings.error_codes.blacklisted }
    elsif not self.valid? 
      return { :message => "Member data is invalid", :code => Settings.error_codes.member_data_invalid }
    end

    if amount.to_f != 0.0
      trans = Transaction.new
      trans.transaction_type = "sale"
      trans.prepare(self, credit_card, amount, self.terms_of_membership.payment_gateway_configuration)
      answer = trans.process
      return answer unless trans.success?
    end

    begin
      self.save!
      if credit_card.member.nil?
        credit_card.member = self
        credit_card.last_digits = credit_card.number.last(4) 
        credit_card.save!
      end
      if trans
        # We cant assign this information before , because models must be created AFTER transaction
        # is completed succesfully
        trans.member_id = self.id
        trans.credit_card_id = credit_card.id
        trans.save
        credit_card.accepted_on_billing
      end

      message = set_status_on_enrollment!(agent, trans, amount)

      self.reload
      { :message => message, :code => Settings.error_codes.success, :member_id => self.id, :v_id => self.visible_id }
    rescue Exception => e
      Auditory.add_redmine_ticket("Member:enroll", e)
      # TODO: this can happend if in the same time a new member is enrolled that makes this
      #     an invalid one. we should revert the transaction.
      message = "Could not save member. #{e}"
      Auditory.audit(agent, self, message, nil, Settings.operation_types.enrollment_billing)
      { :message => message, :code => Settings.error_codes.member_save }
    end
  end

  def send_pre_bill
    if can_bill_membership?
      Communication.deliver!(:prebill, self)
    end
  end
  
  def send_fulfillment
    # we always send fulfillment to new members or members that do not have 
    # opened fulfillments (meaning that previous fulfillments expired).
    if self.fulfillments.find_by_status('open').nil?
      fulfillments_products_to_send.each do |product|
        f = Fulfillment.new :product => product
        f.member_id = self.uuid
        f.assigned_at = DateTime.now
        f.save
      end
    end
  end

  def api_member
    @api_member ||= eval(club.api_type).new self
  end

  def synced?
    self.last_synced_at && self.last_synced_at > self.updated_at
  end

  
  private
    def set_status_on_enrollment!(agent, trans, amount)
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

      message = "Member #{description} successfully $#{amount} on TOM(#{terms_of_membership_id}) -#{terms_of_membership.name}-"
      Auditory.audit(agent, 
        (trans.nil? ? terms_of_membership : trans), 
        message, self, operation_type)
      message
    end

    def fulfillments_products_to_send
      # TODO: this must be review after #19110 is finished
      if enrollment_info and enrollment_info[:megachannel].include?('sloop')
        [ Settings.fulfillment_products.sloop, Settings.fulfillment_products.kit_card ]
      else
        [ Settings.fulfillment_products.kit_card ]
      end
    end

    def record_date
      self.member_since_date = DateTime.now
    end

    def schedule_renewal
      new_bill_date = self.bill_date + eval(terms_of_membership.installment_type)
      if terms_of_membership.monthly?
        self.quota = self.quota + 1
        if self.recycled_times > 1
          new_bill_date = DateTime.now + eval(terms_of_membership.installment_type)
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

      set_as_canceled = false
      if decline.nil?
        # we must send an email notifying about this error. Then schedule this job to run in the future (1 month)
        message = "Billing error but no decline rule configured: #{trans.response_code} #{trans.gateway}: #{trans.response}"
        self.next_retry_bill_date = Date.today + eval(Settings.next_retry_on_missing_decline)
        Notifier.decline_strategy_not_found(message, self).deliver!
        Auditory.audit(nil, trans, message, self, Settings.operation_types.membership_billing_without_decline_strategy)
      else
        trans.update_attribute :decline_strategy_id, decline.id
        if decline.hard_decline?
          message = "Hard Declined: #{trans.response_code} #{trans.gateway}: #{trans.response_result}"
          set_as_canceled = true
        else
          message="Soft Declined: #{trans.response_code} #{trans.gateway}: #{trans.response_result}"
          if trans.response_code == Settings.error_codes.credit_card_blank_with_grace
            self.next_retry_bill_date = terms_of_membership.grace_period.to_i.days.from_now
          else
            self.next_retry_bill_date = decline.days.days.from_now
          end
          if self.recycled_times > (decline.limit-1)
            message = "Soft recycle limit (#{self.recycled_times}) reached: #{trans.response_code} #{trans.gateway}: #{trans.response_result}"
            set_as_canceled = true
          end
        end
      end
      if set_as_canceled
        Auditory.audit(nil, trans, message, self, Settings.operation_types.membership_billing_hard_decline)
        set_as_canceled!
      else
        Auditory.audit(nil, trans, message, self, Settings.operation_types.membership_billing_soft_decline)
        increment(:recycled_times, 1)
      end
      message
    end
end
