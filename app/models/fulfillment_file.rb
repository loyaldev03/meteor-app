class FulfillmentFile < ActiveRecord::Base
  # attr_accessible :title, :body
  has_and_belongs_to_many :fulfillments
  belongs_to :agent
  belongs_to :club

  state_machine :status, :initial => :not_ready do
    after_transition :in_process => :sent, :do => :mark_fulfillments_as_sent

    event :is_ready do
      transition :not_ready => :in_process
    end

    event :processed do
      transition :in_process => :sent
    end
    
    #First state. Creation process was started. 
    state :not_ready
    #Creation process was finished. 
    state :in_process
    #Manually set through CS. Every fulfillment inside was processed.
    state :sent 
  end

  def dates
    self.all_times ? "All times" : "from #{self.initial_date} to #{self.end_date}"
  end

  def fulfillments_processed
    [ fulfillments.where_in_process.count, fulfillments.count ].join(' / ')
  end

  def mark_fulfillments_as_in_process
    self.fulfillments.each { |x| x.update_status(agent, 'in_process', 'Fulfillment file generated', self.id)  unless x.in_process? or x.renewed? }
  end

  def mark_fulfillments_as_sent
    self.fulfillments.where_in_process.each { |x| x.update_status(agent, 'sent', 'Fulfillment file set as sent', self.id) }
  end

  def kit_kard_type?
    self.product == Settings.kit_card_product
  end

  def process_fulfillments_for_file(fulfillment_selected)
  fulfillment_selected.each do |fs|
    fulfillment = Fulfillment.find(fs.first)
    self.fulfillments << fulfillment
    fulfillment.update_status(self.agent, "in_process", "Fulfillment file generated", self.id)
  end
  self.is_ready!
  rescue Exception => e
    Auditory.report_issue("FulfillmentFile turn inalid when generating it.", e, { :fulfillment_file => ff.inspect })
  end
  handle_asynchronously :process_fulfillments_for_file

  def generateXLS(change_status = false)
    package = Axlsx::Package.new
    package.workbook.add_worksheet(:name => "Fulfillments") do |sheet|
      if self.kit_kard_type?
        sheet.add_row Fulfillment::KIT_CARD_HEADER
      else
        sheet.add_row Fulfillment::SLOOPS_HEADER
      end
      self.fulfillments.each do |fulfillment|
        row = fulfillment.get_file_line(change_status, self)
        sheet.add_row row unless row.empty?
      end
    end
    package
  end

  def send_email_with_file(only_in_progress)
    if only_in_progress
      fulfillments = self.fulfillments.where_in_process.includes(:member)
    else
      fulfillments = self.fulfillments.includes(:member)
    end
    xls_package = self.generateXLS(false)
    temp_file = Tempfile.new("fulfillment_file_#{self.id}.xls")
    xls_package.serialize temp_file.path
    
    temp_file.close
    Notifier.manual_fulfillment_file(self.agent,self,temp_file).deliver!
    temp_file.unlink
  end
  handle_asynchronously :send_email_with_file, :queue => :email_queue, priority: 5

end
