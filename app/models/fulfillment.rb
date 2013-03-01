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
  has_and_belongs_to_many :fulfillment_files

  before_create :set_default_values

  SLOOPS_HEADER = ['PackageId', 'Costcenter', 'Companyname', 'Address', 'City', 'State', 'Zip', 'Endorsement', 
              'Packagetype', 'Divconf', 'Bill Transportation', 'Weight', 'UPS Service']
  KIT_CARD_HEADER = ['Member Number','Member First Name','Member Last Name','Member Since Date','Member Expiration Date',
                'ADDRESS','CITY','ZIP','Product','Charter Member Status' ]

  scope :where_bad_address, lambda { where("status = 'bad_address'") }
  scope :where_in_process, lambda { where("status = 'in_process'") }
  scope :where_not_processed, lambda { where("status = 'not_processed'") }
  scope :where_to_set_bad_address, lambda { where("status IN ('not_processed','in_process','out_of_stock','returned')") }
  scope :where_cancellable, lambda { where("status IN ('not_processed','in_process','out_of_stock','bad_address')") }
  scope :type_others, lambda { where(["product_sku NOT IN (?)", Settings.kit_card_product])}

  scope :not_renewed, lambda { where("renewed = false") }

  scope :to_be_renewed, lambda { where([ " date(renewable_at) <= ? " + 
    " AND fulfillments.status NOT IN ('canceled', 'in_process') " + 
    " AND recurrent = true AND renewed = false ", Time.zone.now.to_date]) }

  delegate :club, :to => :member

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
    event :set_as_sent do
      transition all => :sent
    end
    event :set_as_out_of_stock do
      transition all => :out_of_stock
    end
    event :set_as_returned do
      transition all => :returned
    end
    event :set_as_canceled do
      transition all => :canceled
    end
    event :set_as_bad_address do
      transition all => :bad_address
    end
  
    #First status. fulfillment is waiting to be processed.
    state :not_processed
    #This status will be automatically set after the new fulfillment list is downloaded. Only if magento 
    #has stock. Stock will be decreased in one.
    state :in_process
    #Used due to some type of error
    state :on_hold
    #Manually set through CS, by selecting all or some fulfillments in in_process status.
    state :sent 
    #Set automatically using Magento, when a representative or supervisor downloads the file with 
    #fulfillments in not_processed status
    state :out_of_stock 
    #Will be similar than Bad address
    state :returned
    #when member gets lapsed status, all not_processed / in_process / Out of stock fulfillments gets this status.
    state :canceled
    #if delivery fail this status is set and wrong address on member file should be filled with the reason
    state :bad_address
  end

  def renew!
    if recurrent and member.can_renew_fulfillment? and not renewed?
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
    f.member_id = self.member_id
    f.recurrent = true
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
        answer = ( member.wrong_address.nil? ? member.set_wrong_address(agent, reason, false) : {:code => Settings.error_codes.success, :message => "Member already set as wrong address."} )
      end
    elsif new_status == 'not_processed'
      answer = decrease_stock! 
    else
      answer = { :code => Settings.error_codes.success }
    end
    self.status = new_status
    self.save    
    if answer[:code] == Settings.error_codes.success        
      self.audit_status_transition(@current_agent, old_status, reason, file)
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
    Auditory.audit(agent, self, message, member, Settings.operation_types["from_#{old_status}_to_#{self.status}"])
    return { :message => message, :code => Settings.error_codes.success }
  rescue 
    message = I18n.t('error_messages.fulfillment_error')
    Auditory.audit(agent, self, message, member, Settings.error_codes.fulfillment_error )
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


  def self.process_fulfillments_up_today
    Fulfillment.to_be_renewed.find_in_batches do |group|
      Rails.logger.info " *** [#{I18n.l(Time.zone.now, :format =>:dashed)}] Starting members:process_fulfillments_up_today rake task, processing #{group.count} fulfillments"
      group.each do |fulfillment| 
        begin
          Rails.logger.info "  * processing member ##{fulfillment.member_id} fulfillment ##{fulfillment.id}"
          fulfillment.renew!
        rescue Exception => e
          Airbrake.notify(:error_class => "Member::Fulfillment", :error_message => "#{e.to_s}\n\n#{$@[0..9] * "\n\t"}", :parameters => { :fulfillment => fulfillment.inspect })
          Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
        end
      end
    end
  end

  def get_file_line(change_status = false, type_others = true)
    return [] if product.nil?
    if change_status
      Fulfillment.find(self.id).set_as_in_process unless self.in_process? or self.renewed?
    end
    member = self.member
    if type_others
      [ self.tracking_code, self.product.cost_center, member.full_name, member.address, member.city,
            member.state, member.zip, 'Return Service Requested', 'Irregulars', 'Y', 'Shipper',
            self.product.weight, 'MID']
    else
      [ member.visible_id, member.first_name, member.last_name, (I18n.l member.member_since_date, :format => :only_date_short),
              (I18n.l self.renewable_at, :format => :only_date_short if self.renewable_at), member.address, member.city,
              "=\"#{member.zip}\"", self.product_sku, ('C' if member.member_group_type_id) ]
    end
  end

  def self.generateXLS(fulfillments, change_status = false, type_others = true)
    package = Axlsx::Package.new
    package.workbook.add_worksheet(:name => "Fulfillments") do |sheet|
      if type_others
        sheet.add_row Fulfillment::SLOOPS_HEADER
      else
        sheet.add_row Fulfillment::KIT_CARD_HEADER
      end
      fulfillments.each do |fulfillment|
        row = fulfillment.get_file_line(true, type_others)
        sheet.add_row row unless row.empty?
      end
    end
    package
  end

  def product
    @product ||= Product.find_by_sku_and_club_id(self.product_sku, self.member.club_id)
  end


  private
    def set_default_values
      self.assigned_at = Time.zone.now
      # 1.year is fixed today, we can change it later if we want to apply rules on our decissions
      if self.recurrent and self.renewable_at.nil?
        self.renewable_at = self.assigned_at + 1.year 
      end
      self.tracking_code = self.product_package.to_s + self.member.visible_id.to_s
    end

end