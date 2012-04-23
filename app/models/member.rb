class Member < ActiveRecord::Base
  include Extensions::UUID
  
  belongs_to :terms_of_membership
  belongs_to :club
  belongs_to :created_by, :class_name => 'Agent', :foreign_key => 'created_by_id'
  has_many :member_notes
  has_many :credit_cards
  has_many :transactions

  attr_accessible :address, :bill_date, :city, :country, :created_by, :description, 
      :email, :enroll_attempts, :external_id, :first_name, :home_phone, 
      :join_date, :last_name, :status, :cancel_date, :next_retry_bill_date, 
      :bill_date, :quota, :state, :terms_of_membership_id, :work_phone, :zip, 
      :club_id, :partner_id
  
  accepts_nested_attributes_for :credit_cards, :limit => 1

  validates :first_name, :presence => true
  validates :email, :presence => true, :uniqueness => { :scope => :club_id }
   # TODO: add the following attributes as required.
   #   t.string :last_name
   #   t.string :email
   #   t.string :address
   #   t.string :city
   #   t.string :state
   #   t.string :zip
   #   t.string :country
   #   t.integer :terms_of_membership_id, :limit => 8

  state_machine :status, :initial => :provisional do
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

  def full_name
    [first_name, last_name].join(' ')
  end

end
