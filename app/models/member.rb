class Member < ActiveRecord::Base
  include Extensions::UUID
  
  belongs_to :terms_of_membership
  belongs_to :club
  belongs_to :created_by, :class_name => 'Agent', :foreign_key => 'created_by_id'
  has_many :member_notes
  has_many :credit_cards
  has_many :transactions

  attr_accessible :address, :bill_date, :city, :country, :created_by, :description, 
      :email, :external_id, :first_name, :phone_number, 
      :join_date, :last_name, :status, :cancel_date, :next_retry_bill_date, 
      :bill_date, :quota, :state, :terms_of_membership_id, :work_phone, :zip, 
      :club_id, :partner_id

  validates :first_name, :presence => true
  validates :email, :presence => true, :uniqueness => { :scope => :club_id }, 
            :format => /^([0-9a-zA-Z]([-\.\w]*[0-9a-zA-Z])*@([0-9a-zA-Z][-\w]*[0-9a-zA-Z]\.)+[a-zA-Z]{2,9})$/
  validates :last_name, :email, :address, :city, :state, :zip, :country, :presence => true
  validates :terms_of_membership_id, :presence => true

  state_machine :status, :initial => :none do
    after_transition [:none, :lapsed] => :provisional, :do => :schedule_first_membership

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
    bill_date = Date.today + terms_of_membership.trial_days
    next_retry_bill_date = bill_date
    if terms_of_membership.monthly?
      quota = 1
    end
    #@membership.save
    #Delayed::Job.enqueue(MembershipBillingJob.new(@membership.id),0,bill_date)
    #Delayed::Job.enqueue(SendRenewJob.new(member_id,bill_date),20,5.minutes.from_now)

  end

  def full_name
    [ first_name, last_name].join(' ')
  end

  def credit_card
    self.credit_cards.find_by_active(true)
  end

  def full_address
    # TODO: something like "#{self.address}, #{self.city}, #{self.state}"
  end

end
