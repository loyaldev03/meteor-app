class Member < ActiveRecord::Base
  include Extensions::UUID
  
  belongs_to :terms_of_membership
  belongs_to :club
  belongs_to :created_by, :class_name => 'Agent', :foreign_key => 'created_by_id'
  has_many :member_notes
  has_many :credit_cards
  has_many :transactions
  has_many :operations

  attr_accessible :address, :bill_date, :city, :country, :created_by, :description, 
      :email, :external_id, :first_name, :phone_number, 
      :join_date, :last_name, :status, :cancel_date, :next_retry_bill_date, 
      :bill_date, :quota, :state, :terms_of_membership_id, :zip, 
      :club_id, :partner_id

  validates :first_name, :presence => true
  validates :email, :presence => true, :uniqueness => { :scope => :club_id }, 
            :format => /^([0-9a-zA-Z]([-\.\w]*[0-9a-zA-Z])*@([0-9a-zA-Z][-\w]*[0-9a-zA-Z]\.)+[a-zA-Z]{2,9})$/
  validates :last_name, :email, :address, :city, :state, :zip, :country, :presence => true
  validates :terms_of_membership_id, :presence => true

  state_machine :status, :initial => :none do
    after_transition [:none, :lapsed, :provisional, :paid] => :provisional, :do => :schedule_first_membership
    after_transition :any => :lapsed, :do => :deactivation

    event :set_as_provisional do
      transition [:none, :lapsed, :paid, :provisional] => :provisional
    end
    event :set_as_paid do
      transition [:provisional, :paid] => :paid
    end
    event :deactivate do
      transition [:provisional, :paid] => :lapsed
    end


    # A Member is within their review period. These members have joined a Subscription program that has a “Provisional” 
    # period whereby the Member has an opportunity to review the benfits of the program risk free for the duration of 
    # the Provisional period. 
    state :provisional
    # A Member who has joineda subscription program that has been successfully billed the the 
    # Membership Billing Amount and is still active in the Program. 
    state :paid
    # Where a Member in Provisional or Paid Status Cancels their Subscription or their Subscription 
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

  def schedule_first_membership
    # TODO: send welcome email 
    self.bill_date = Date.today + terms_of_membership.trial_days
    self.next_retry_bill_date = bill_date
    if terms_of_membership.monthly?
      self.quota = 1
    end
    self.join_date = DateTime.now 
    self.save
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

  def can_save_the_sale?
    self.paid? or self.provisional?
  end

  def can_bill_membership?
    self.paid? or self.provisional?
  end

  def save_the_sale(new_tom_id, agent = nil)
    if can_save_the_sale?
      if new_tom_id.to_i == self.terms_of_membership_id.to_i
        { :message => "Nothing to change. Member is already enrolled on that TOM.", :code => "9885" }
      else
        Auditory.audit(agent, self, "Save the sale from TOMID #{self.terms_of_membership_id} to TOMID #{new_tom_id}", self)
        self.terms_of_membership_id = new_tom_id
        enroll(self.active_credit_card, 0.0, agent)
      end
    else
      { :message => "Member status does not allows us to save the sale.", :code => "9886" }
    end
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
            { :code => "9999", :message => "Credit card is blank. Allowing grace period" }
          else
            { :code => "9997", :message => "Credit card is blank and grace period is disabled" }
          end
        else
          # TODO: @member.cc_year_exp=card_expired_rule(@member.cc_year_exp)
          trans = Transaction.new
          trans.transaction_type = "sale"
          trans.prepare(self, self.active_credit_card, amount, self.terms_of_membership.payment_gateway_configuration)
          answer = trans.process
          if trans.success?
            active_credit_card.accepted_on_billing
            set_as_paid!
            schedule_renewal
            message = "Member billed successfully $#{amount} Transaction id: #{trans.id}"
            Auditory.audit(nil, self, message, self)
            { :message => message, :code => "000", :member_id => self.id }
          else
            set_decline_strategy(trans)
            Auditory.audit(nil, self, answer)
            Auditory.add_redmine_ticket
            answer
          end
        end
      else
        { :message => "Called billing method but no amount on TOM is set.", :code => "9887" }
      end
    else
      { :message => "Member is not in a billing status.", :code => "9886" }
    end
  end

  def enroll(credit_card, amount, agent = nil)
    if amount.to_f != 0.0
      trans = Transaction.new
      trans.transaction_type = "sale"
      trans.prepare(self, credit_card, amount, self.terms_of_membership.payment_gateway_configuration)
      answer = trans.process
      return answer unless trans.success?
    end

    begin
      save!
      if credit_card.member.nil?
        credit_card.member = self 
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
      set_as_provisional! # set join_date
      message = "Member enrolled successfully $#{amount} on TOM(#{terms_of_membership_id}) -#{terms_of_membership.name}-"
      Auditory.audit(agent, self, message, self)
      self.reload
      { :message => message, :code => "000", :member_id => self.id, :v_id => self.visible_id }
    rescue Exception => e
      # TODO: Notify devels about this!
      # TODO: this can happend if in the same time a new member is enrolled that makes this
      #     an invalid one. we should revert the transaction.
      message = "Could not save member. #{e}"
      Auditory.audit(agent, self, message)
      { :message => message, :code => 404 }
    end
  end

  private

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
      bill_date = new_bill_date
      next_retry_bill_date = new_bill_date
      self.save
      # TODO: Audit 
    end

    def send_pre_bill
      # TODO: send prebill email
    end

    def deactivation
      self.next_retry_bill_date = nil
      self.bill_date = nil
      # TODO: Audit 
    end

    def set_decline_strategy(trans)
      # soft / hard decline
      type = self.terms_of_membership.installment_type
      decline = DeclineStrategy.find_by_gateway_and_response_code_and_installment_type_and_credit_card_type(trans.gateway.downcase, 
                  trans.response_code, type, trans.credit_card_type) || 
                DeclineStrategy.find_by_gateway_and_response_code_and_installment_type_and_credit_card_type(trans.gateway.downcase, 
                  trans.response_code, type, "all")

      deactivate = false
      if decline.nil?
        # we must send an email notifying about this error. Then schedule this job to run in the future (1 month)
        message = "Billing error but no decline rule configured: #{trans.response_code} #{trans.gateway}: #{trans.response}"
        self.next_retry_bill_date = Date.today + 30.days
        Notifier.decline_strategy_not_found(message, self).deliver!
      else
        trans.update_attribute :decline_strategy_id, decline.id
        if decline.hard_decline?
          message = "Hard Declined: #{trans.response_code} #{trans.gateway}: #{trans.response}"
          deactivate = true
        else
          message="Soft Declined: #{trans.response_code} #{trans.gateway}: #{trans.response}"
          if trans.response_code == "9999"
            self.next_retry_bill_date = terms_of_membership.grace_period.to_i.days.from_now
          else
            self.next_retry_bill_date = decline.days.days.from_now
          end
          if self.recycled_times > (decline.limit-1)
            message = "Soft decline limit (#{self.recycled_times}) reached: #{trans.response_code} #{trans.gateway}: #{trans.response}"
            deactivate = true
          end
        end
      end
      if deactivate
        deactivate!
      else
        increment(:recycled_times, 1)
      end
    end
end
