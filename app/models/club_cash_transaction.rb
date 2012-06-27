class ClubCashTransaction < ActiveRecord::Base
  belongs_to :member

  before_save :update_member_amount

  attr_accessible :amount, :description

  validates :amount, :presence => true

  def update_member_amount
  	member = Member.find(member_id)
  	member.add_club_cash(amount)
  end

end