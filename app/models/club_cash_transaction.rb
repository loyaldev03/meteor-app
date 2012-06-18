class ClubCashTransaction < ActiveRecord::Base
  belongs_to :member

  before_create :update_member_amount

  attr_accessible :amount, :description

  validates :amount, :presence => true , :format => /^\d+??(?:\.\d{0,2})?$/ 

  def update_member_amount
  	member = Member.find(member_id)
  	member.add_club_cash(amount)
  end

end