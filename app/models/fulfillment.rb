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

  scope :where_undeliverable, lambda { where("status = 'undeliverable'") }
  scope :where_processing, lambda { where("status = 'processing'") }
  scope :where_not_processed, lambda { where("status = 'not_processed'") }
  scope :where_cancellable, lambda { where("status IN ('not_processed','processing','out_of_stock', 'undeliverable')") }
  scope :type_card, lambda{ where("product_sku = 'CARD'")}
  scope :type_kit, lambda{ where("product_sku = 'KIT'")}
  scope :type_others, lambda{ where("product_sku NOT IN ('KIT','CARD')")}

  delegate :club, :to => :member

  state_machine :status, :initial => :not_processed do
    after_transition all => :not_processed, :do => :decrease_stock

    event :set_as_not_processed do
      transition [:sent, :out_of_stock, :undeliverable, :not_processed] => :not_processed
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

  def renew!
    if recurrent and membership_billed_recently?
      if undeliverable?
        self.new_fulfillment('undeliverable')
      else
        self.new_fulfillment
      end
      self.set_as_canceled! unless self.sent?
    end
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

  def validate_stock
    if product.nil? or not product.has_stock?
      set_as_out_of_stock
      false
    else
      product.decrease_stock
      true
    end
  end

  def resend(agent)
    set_as_not_processed!
    self.assigned_at = Time.zone.now
    self.save
    message = "Fulfillment #{self.product_sku} was marked to be delivered next time."
    Auditory.audit(agent, self, message, member, Settings.operation_types.resend_fulfillment)
    { :message => message, :code => Settings.error_codes.success }
  rescue 
    Auditory.audit(agent, self, message, member, Settings.error_codes.fulfillment_out_of_stock )
    { :message => "Product does not have stock.", :code => Settings.error_codes.fulfillment_out_of_stock }
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

  def self.generateCSV(fulfillments, type_others = true)
    CSV.generate do |csv| 
      if type_others
        csv << ['PackageId', 'Costcenter', 'Companyname', 'Address', 'City', 'State', 'Zip', 'Endorsement', 
              'Packagetype', 'Divconf', 'Bill Transportation', 'Weight', 'UPS Service']
      else
        csv << ['Member Number','First Name','Member Last Name','Member Since Date','Member Expiration Date',
                'ADDRESS','CITY','ZIP','Product','Charter Member Status' ]
      end

      fulfillments.each do |fulfillment|
        Fulfillment.find(fulfillment.id).set_as_processing unless fulfillment.processing?
        member = fulfillment.member
        if type_others
          csv << [fulfillment.tracking_code, 'Costcenter', member.full_name, member.address, member.city,
                member.state, member.zip, 'Return Service Requested', 'Irregulars', 'Y', 'Shipper',
                fulfillment.product.weight, 'MID']
        else
          csv << [member.visible_id, member.first_name, member.last_name, (I18n.l member.member_since_date, :format => :only_date_short),
                  (I18n.l fulfillment.renewable_at, :format => :only_date_short if fulfillment.renewable_at), member.address, member.city,
                  member.zip, fulfillment.product_sku, ('C' if member.member_group_type_id) ]
        end
      end
    end
  end

  def product
    @product ||= Product.find_by_sku_and_club_id(self.product_sku, self.member.club_id)
  end

  private
    def membership_billed_recently?
      true
    end

    def decrease_stock
      validate_stock
    end

    def set_default_values
      self.assigned_at = Time.zone.now
      # 1.year is fixed today, we can change it later if we want to apply rules on our decissions
      self.renewable_at = self.assigned_at + 1.year if self.recurrent
      self.tracking_code = self.product_sku + self.member.visible_id.to_s
    end

end
