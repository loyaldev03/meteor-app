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

  scope :new, lambda { where("status = 'new'") }


  state_machine :status, :initial => :new do
    event :set_as_new do
      transition [:out_of_stock,:undeliverable] => :new
    end
    event :set_as_processing do
      transition :open => :processing
    end
    event :set_as_sent do
      transition :processing => :sent
    end
    event :set_as_out_of_stock do
      transition :new => :out_of_stock
    end
    event :set_as_canceled do
      transition [:new,:processing,:out_of_stock] => :canceled
    end
    event :set_as_undeliverable do
      transition :processing => :undeliverable
    end
    
    #First status. fulfillment is waiting to be processed.
    state :new
    #This status will be automatically set after the new fulfillment list is downloaded. Only if magento 
    #has stock. Stock will be decreased in one.
    state :processing
    #Manually set through CS, by selecting all or some fulfillments in processing status.
    state :sent 
    #Set automatically using Magento, when a representative or supervisor downloads the file with 
    #fulfillments in new status
    state :out_of_stock 
    #when member gets lapsed status, all new / processing / Out of stock fulfillments gets this status.
    state :canceled
    #if delivery fail this status is set and wrong address on member file should be filled with the reason
    state :undeliverable

  end

  def renew
    self.set_as_archived!
    if member.can_receive_another_fulfillment?
      f = Fulfillment.new 
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
    end
end
