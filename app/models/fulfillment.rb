#
# assigned_at => The day this fulfillment is assigned to our member.
#     If fulfillment is resend it is because of a wrong address. 
#     this value will be updated.
# renewable_at => This day is assigned_at + 1.year (at first time). 
#     Will be used by fulfillment script to check which members need a new fulfillment
# status => open , archived
#
class Fulfillment < ActiveRecord::Base
  attr_accessible :product_sku

  belongs_to :member

  before_create :set_default_values

  scope :undeliverable, lambda { where("status = 'undeliverable'") }
  scope :processing, lambda { where("status = 'processing'") }
  scope :not_processed, lambda { where("status = 'not_processed'") }
  scope :cancellable, lambda { where("status IN ('not_processed','processing','out_of_stock', 'undeliverable')") }

  delegate :club, :to => :member

  state_machine :status, :initial => :not_processed do
    after_transition :all => :processing, :do => :decrease_stock

    event :set_as_not_processed do
      transition [:sent,:out_of_stock,:undeliverable] => :not_processed
    end
    event :set_as_processing do
      transition :not_processed => :processing
    end
    event :set_as_sent do
      transition :processing => :sent
    end
    event :set_as_out_of_stock do
      transition :not_processed => :out_of_stock
    end
    event :set_as_canceled do
      transition [:not_processed,:processing,:out_of_stock, :undeliverable] => :canceled
    end
    event :set_as_undeliverable do
      transition :processing => :undeliverable
    end
    
    #First status. fulfillment is waiting to be processed.
    state :not_processed
    #This status will be automatically set after the new fulfillment list is downloaded. Only if magento 
    #has stock. Stock will be decreased in one.
    state :processing
    #Manually set through CS, by selecting all or some fulfillments in processing status.
    state :sent 
    #Set automatically using Magento, when a representative or supervisor downloads the file with 
    #fulfillments in not_processed status
    state :out_of_stock 
    #when member gets lapsed status, all not_processed / processing / Out of stock fulfillments gets this status.
    state :canceled
    #if delivery fail this status is set and wrong address on member file should be filled with the reason
    state :undeliverable
  end

  def renew!(undeliverable = false)
    if recurrent
      if undeliverable?
        self.new_fulfillment('undeliverable')
      else
        self.new_fulfillment
      end
    end
    self.set_as_canceled! unless self.sent?
  end

  def new_fulfillment(status = nil)
    if member.can_receive_another_fulfillment?
      f = Fulfillment.new 
      f.status = status if status.nil?
      f.product_sku = self.product_sku
      f.member_id = self.member_id
      f.save
    end
  end

  def validate_stock!
    raise "out of stock" unless validate_stock
  end

  def validate_stock
    if product.nil? or not product.has_stock?
      set_as_out_of_stock
      false
    else
      true
    end
  end

  def resend(agent)
    validate_stock!
    set_as_not_processed!
    message = "Fulfillment #{self.product_sku} was marked to be delivered next time."
    Auditory.audit(agent, self, message, member, Settings.operation_types.fulfillment_resend)
    { :message => message, :code => Settings.error_codes.success }
  rescue 
    # TODO: add operation, replate fulfillment_error for fulfillment_out_of_stock
    { :message => "Product does not have stock.", :code => Settings.error_codes.fulfillment_error }
  end

  def mark_as_sent(agent)
    if self.set_as_sent
      message = "Fulfillment #{self.product_sku} was set as sent."
      Auditory.audit(agent, self, message, member, Settings.operation_types.fulfillment_mannualy_mark_as_sent)
      { :message => message, :code => Settings.error_codes.success }
    else
      message = "Could not be marked as sent."
      { :message => message, :code => Settings.error_codes.fulfillment_error }
    end
  end

  def self.generateCSV(fulfillments)
    CSV.generate do |csv| 
      csv << ['PackageId', 'Costcenter', 'Companyname', 'Address', 'City', 'State', 'Zip', 'Endorsement', 
              'Packagetype', 'Divconf', 'Bill Transportation', 'Weight', 'UPS Service']
      fulfillments.each do |fulfillment|
        if fulfillment.validate_stock
          member = fulfillment.member
          fulfillment.set_as_processing
          csv << [fulfillment.tracking_code, 'Costcenter', member.full_name, member.address, member.city,
                  member.state, member.zip, 'Return Service Requested', 'Irregulars', 'Y', 'Shipper',
                  product.weight, 'MID']
        end
      end
    end
  end

  def product
    @product ||= Product.find_by_sku_and_club_id(product_sku, member.club_id)
  end

  private
    def decrease_stock
      product.decrease_stock
    end

    def set_default_values
      self.assigned_at = Time.zone.now
      # 1.year is fixed today, we can change it later if we want to apply rules on our decissions
      self.renewable_at = self.assigned_at + 1.year if self.recurrent
      self.tracking_code = self.product_sku + self.member.visible_id.to_s
    end

end
