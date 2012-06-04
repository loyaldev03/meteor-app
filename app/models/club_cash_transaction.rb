class ClubCashTransaction < ActiveRecord::Base
  belongs_to :member

  after_save :update_member_amount

  attr_accessible :amount, :description

  validates :amount, :presence => true , :format => /^\d+??(?:\.\d{0,2})?$/ 


  def update_member_amount
  	member = Member.find(member_id)
  	total_amount = amount + member.club_cash_amount
  	member.update_attribute(:club_cash_amount, total_amount)
  end

end