#
# assigned_at => The day this fulfillment is assigned to our member.
# delivered_at => The day CS or our delivery provider send the fulfillment. 
#     If fulfillment is resend it is because of a wrong address. 
#     this value will be updated.
# renewable_at => This day is assigned_at + 1.year (at first time). 
#     Will be used by fulfillment script to check which members need a new fulfillment
# status => open , archived
#
class Fulfillment < ActiveRecord::Base
  attr_accessible :product

  belongs_to :member

  before_create :set_renewable_at

  scope :open, lambda { where("status = 'open'") }


  state_machine :status, :initial => :open do
    event :set_as_archived do
      transition :open => :archived
    end

    # fulfillments in archived status will be used as history only.
    state :archived
    # fulfillments in open status can be re-sended
    state :open
  end

  def renew
    self.set_as_archived!
    if member.can_receive_another_fulfillment?
      f = Fulfillment.new :
      f.product = self.product
      f.member_id = self.member_id
      f.assigned_at = Time.zone.now
      f.save
    end
  end

  private
    # 1.year is fixed today, we can change it later if we want to apply rules on our decissions
    def set_renewable_at
      self.renewable_at = self.assigned_at + 1.year
      self.delivered_at = Time.zone.now
    end
end
