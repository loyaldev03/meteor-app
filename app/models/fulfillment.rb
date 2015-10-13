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

  belongs_to :user
  belongs_to :club
  has_and_belongs_to_many :fulfillment_files

  before_create :set_default_values
  after_update :replenish_stock

  SLOOPS_HEADER = ['PackageId', 'Costcenter', 'Companyname', 'Address', 'City', 'State', 'Zip', 'Endorsement', 
              'Packagetype', 'Divconf', 'Bill Transportation', 'Weight', 'UPS Service']
  KIT_CARD_HEADER = ['Member Number','Member First Name','Member Last Name','Member Since Date','Member Expiration Date',
                'ADDRESS','CITY','STATE','ZIP','Product','Charter Member Status' ]

  scope :where_bad_address, lambda { where("status in ('bad_address','returned')") }
  scope :where_in_process, lambda { where("status = 'in_process'") }
  scope :where_not_processed, lambda { where("status = 'not_processed'") }
  scope :where_to_set_bad_address, lambda { where("status IN ('not_processed','in_process','out_of_stock','returned')") }
  scope :where_cancellable, lambda { where("status IN ('not_processed','in_process','out_of_stock','bad_address')") }
  scope :type_others, lambda { where(["product_sku NOT IN (?)", Settings.kit_card_product])}

  scope :not_renewed, lambda { where("renewed = false") }

  scope :to_be_renewed, lambda { joins(:user => :club).readonly(false).where([ 
    " date(renewable_at) <= ? AND fulfillments.status NOT IN ('canceled', 'in_process') 
      AND recurrent = true AND renewed = false AND clubs.billing_enable = true 
      AND users.status = 'active' AND users.recycled_times = 0",  
    Time.zone.now.to_date]) }

  delegate :club, :to => :user

  state_machine :status, :initial => :not_processed do

    event :set_as_not_processed do
      transition all => :not_processed
    end
    event :set_as_in_process do
      transition all => :in_process
    end
    event :set_as_on_hold do
      transition all => :on_hold
    end
    event :set_as_out_of_stock do
      transition all => :out_of_stock
    end
    event :set_as_returned do
      transition all => :returned
    end
    event :set_as_sent do
      transition all => :sent
    end
    event :set_as_bad_address do
      transition all => :bad_address
    end
    event :set_as_canceled do
      transition all => :canceled
    end
    #First status. fulfillment is waiting to be processed. Stock will be decreased by one.
    state :not_processed
    #This status will be automatically set after the new fulfillment list is downloaded.
    state :in_process
    #Used due to some type of error
    state :on_hold
    #Manually set through CS, by selecting all or some fulfillments in in_process status. Also, when we 
    #mark as sent a fulfillment file, we set every fulfillment related to it as sent.
    state :sent 
    #Set automatically using Magento, when a representative or supervisor downloads the file with 
    #fulfillments in not_processed status
    state :out_of_stock 
    #Will be similar than Bad address
    state :returned
    #when member gets lapsed status, all not_processed / in_process / out_of_stock / bad_address fulfillments gets this status.
    state :canceled
    #if delivery fail this status is set and wrong address on member file should be filled with the reason. If the member
    #is set as undeliverable every fulfillment in 'not_processed','in_process','out_of_stock' and 'returned' will also be
    #set as 'bad_address' 
    state :bad_address
  end

  def renew!
    if recurrent and user.can_renew_fulfillment? and not renewed?
      if self.bad_address?
        self.new_fulfillment('bad_address')
      else
        self.new_fulfillment
      end
      self.renewed = true
      self.save
    end
  end

  def new_fulfillment(status = nil)
    f = Fulfillment.new 
    f.status = status  unless status.nil?
    f.product_sku = self.product_sku
    f.product_package = self.product_package
    f.user_id = self.user_id
    f.recurrent = true
    f.club_id = self.club_id
    f.save
    f.decrease_stock! if status.nil?
  end

  def decrease_stock!
    old_status = self.status
    if product.nil? 
      {:message => I18n.t('error_messages.product_empty'), :code => Settings.error_codes.product_empty}
    elsif not product.has_stock?
      {:message => I18n.t('error_messages.product_out_of_stock'), :code => Settings.error_codes.product_out_of_stock}
    else
      product.decrease_stock
      {:message => "Stock reduced with success", :code => Settings.error_codes.success}
    end
  end

  def replenish_stock
    if status_changed? and status == 'canceled'
      product.replenish_stock
    end
  end

  def update_status(agent, new_status, reason, file = nil)
    old_status = self.status
    if renewed?
      return {:message => I18n.t("error_messages.fulfillment_is_renwed") , :code => Settings.error_codes.fulfillment_error }
    elsif new_status.blank?
      return {:message => I18n.t("error_messages.fulfillment_new_status_blank") , :code => Settings.error_codes.fulfillment_error }
    elsif old_status == new_status
      return {:message => I18n.t("error_messages.fulfillment_new_status_equal_to_old", :fulfillment_sku => self.product_sku) , :code => Settings.error_codes.fulfillment_error }
    elsif new_status == 'bad_address' or new_status == 'returned'
      if reason.blank?
        return {:message => I18n.t("error_messages.fulfillment_reason_blank"), :code => Settings.error_codes.fulfillment_reason_blank}
      else
        answer = ( user.wrong_address.nil? ? user.set_wrong_address(agent, reason, false) : {:code => Settings.error_codes.success, :message => "Member already set as wrong address."} )
      end
    elsif new_status == 'not_processed'
      answer = decrease_stock!
    else
      answer = { :code => Settings.error_codes.success }
    end
    self.status = new_status
    self.save
    if answer[:code] == Settings.error_codes.success        
      self.audit_status_transition(agent, old_status, reason, file)
    else
      answer
    end
  end

  def audit_status_transition(agent, old_status, reason = nil, file = nil)
    self.reload
    if file.nil?
      message = "Changed status on Fulfillment ##{self.id} #{self.product_sku} from #{old_status} to #{self.status}" + (reason.blank? ? "" : " - Reason: #{reason}")
    else
      message = "Changed status on File ##{file} Fulfillment ##{self.id} #{self.product_sku} from #{old_status} to #{self.status}" + (reason.blank? ? "" : " - Reason: #{reason}")
    end
    Auditory.audit(agent, self, message, user, Settings.operation_types["from_#{old_status}_to_#{self.status}"])
    return { :message => message, :code => Settings.error_codes.success }
  rescue Exception => e
    message = I18n.t('error_messages.fulfillment_error')
    Auditory.audit(agent, self, message, user, Settings.error_codes.fulfillment_error )
    return { :message => message, :code => Settings.error_codes.fulfillment_error }
  end

  # def resend(agent)
  #   if product.nil? 
  #     raise "Product does not have stock."
  #   end
  #   if bad_address?
  #     raise "Fulfillment is bad_address"
  #   end

  #   self.decrease_stock!
  #   self.assigned_at = Time.zone.now
  #   self.save
  #   message = "Fulfillment #{self.product_sku} was marked to be delivered next time."
  #   Auditory.audit(agent, self, message, member, Settings.operation_types.resend_fulfillment)
  #   { :message => message, :code => Settings.error_codes.success }
  # rescue 
  #   Auditory.audit(agent, self, message, member, Settings.error_codes.fulfillment_out_of_stock )
  #   { :message => I18n.t('error_messages.fulfillment_out_of_stock'), :code => Settings.error_codes.fulfillment_out_of_stock }
  # end

  def get_file_line(change_status = false, fulfillment_file)
    return [] if product.nil?
    if change_status
      Fulfillment.find(self.id).update_status(fulfillment_file.agent_id, "in_process", "Fulfillment file generated", fulfillment_file.id) unless self.in_process? or self.renewed?
    end
    user = self.user
    if fulfillment_file.kit_kard_type?
      [ user.id, user.first_name, user.last_name, (I18n.l user.member_since_date, :format => :only_date_short),
              (I18n.l self.renewable_at, :format => :only_date_short if self.renewable_at), user.address, user.city,
              user.state,"=\"#{user.zip}\"", self.product_sku, ('C' if user.member_group_type_id) ]
    else
      [ self.tracking_code, self.product.cost_center, user.full_name, user.address, user.city,
            user.state, user.zip, 'Return Service Requested', 'Irregulars', 'Y', 'Shipper',
            self.product.weight, 'MID']
    end
  end

  def product
    @product ||= Product.find_by_sku_and_club_id(self.product_sku, self.user.club_id)
  end

  private
    def set_default_values
      self.assigned_at = Time.zone.now
      # 1.year is fixed today, we can change it later if we want to apply rules on our decissions
      if self.recurrent and self.renewable_at.nil?
        self.renewable_at = self.assigned_at + 1.year 
      end
      self.tracking_code = self.product_package.to_s + self.user.id.to_s
    end

end
