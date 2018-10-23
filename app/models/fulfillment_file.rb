class FulfillmentFile < ActiveRecord::Base
  # attr_accessible :title, :body
  has_and_belongs_to_many :fulfillments
  belongs_to :agent
  belongs_to :club

  state_machine :status, initial: :in_process do
    after_transition in_process: :sent, do: :mark_fulfillments_as_sent
    after_transition packed: :sent, do: :mark_fulfillments_as_sent
    
    event :processed do
      transition in_process: :sent
    end

    event :processed_and_packed do
      transition packed: :sent
    end

    event :pack do
      transition in_process: :packed
    end
    
    #First status. fulfillment file was created
    state :in_process
    # Manually set through CS: https://www.pivotaltracker.com/story/show/160935111/comments/195021037
    state :packed
    #Manually set through CS. Every fulfillment inside was processed.
    state :sent 
  end

  def dates
    self.all_times ? "All times" : "from #{self.initial_date} to #{self.end_date}"
  end

  def fulfillments_processed
    [ fulfillments.where_in_process.count, self.fulfillment_count ].join(' / ')
  end

  def mark_fulfillments_as_in_process
    self.fulfillments.each { |x| x.update_status(agent, 'in_process', 'Fulfillment file generated', self.id)  unless x.in_process? or x.renewed? }
  end

  def mark_fulfillments_as_sent
    self.fulfillments.where_in_process.each { |x| x.update_status(agent, 'sent', 'Fulfillment file set as sent', self.id) }
  
    if club.has_store_configured?
      fulfillments.pluck(:id).in_groups_of(100).each do |group|
        Store::FulfillmentFileFulfillJob.perform_later(self, group.compact)
      end
    end
  end

  def generateXLS(change_status = false)
    package = Axlsx::Package.new
    package.workbook.add_worksheet(name: "Fulfillments") do |sheet|
      sheet.add_row ['PackageId', 'Costcenter', 'Companyname', 'Address', 'City', 'State', 
              'Zip', 'Endorsement', 'Packagetype', 'Divconf', 'Bill Transportation', 'Weight', 
              'UPS Service']
      self.fulfillments.each do |fulfillment|
        row = fulfillment.get_file_line(change_status, self)
        sheet.add_row row unless row.empty?
      end
    end
    package
  end

  def send_email_with_file(only_in_progress)
    if only_in_progress
      fulfillments = self.fulfillments.where_in_process.includes(:user)
    else
      fulfillments = self.fulfillments.includes(:user)
    end
    xls_package = self.generateXLS(false)
    temp_file = Tempfile.new("fulfillment_file_#{self.id}.xls")
    xls_package.serialize temp_file.path
    
    temp_file.close
    Notifier.manual_fulfillment_file(self.agent,self,temp_file).deliver_now!
    temp_file.unlink
  end

end
