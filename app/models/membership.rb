class Membership < ActiveRecord::Base
  belongs_to :terms_of_membership
  belongs_to :member
  belongs_to :created_by, :class_name => 'Agent', :foreign_key => 'created_by_id'
  has_one :enrollment_info
  has_many :transactions

  attr_accessible :created_by, :join_date, :status, :cancel_date, :quota, :terms_of_membership_id

  before_create :set_default_quota

  # validates :terms_of_membership, :presence => true
  # validates :member, :presence => true

  def self.datatable_columns
    ['id', 'status', 'tom', 'join_date', 'cancel_date', 'quota' ]
  end

  private 
    def set_default_quota
      quota = (terms_of_membership.monthly? ? 1 :  0)
    end
  
end

