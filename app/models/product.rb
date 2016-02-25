class Product < ActiveRecord::Base
  belongs_to :club
  has_many :fulfillments

  validates :sku, presence: true, format: /\A[0-9a-zA-Z\-_]+\z/, length: { minimum: 2 }, uniqueness: { scope: [:club_id, :deleted_at] }
  validates :cost_center, format: /\A[a-zA-Z\-_]+\z/, length: { minimum: 2, maximum: 30 }, allow_nil: true
  validates :name, presence: true

  validates :package, format: /\A[a-zA-Z\-_]+\z/, length: { maximum: 19 }
  validates :stock, numericality: { only_integer: true, less_than: 1999999 }, allow_backorder: true

  scope :with_stock, -> { where('(allow_backorder = true) OR (allow_backorder = false and stock > 0)') }

  before_save :apply_upcase_to_sku
  before_update :validate_sku_update
  before_destroy :no_fulfillment_related?

  acts_as_paranoid

  BULK_PROCESS_FIELDS = [ :sku, :name, :package, :stock_to_add, :allow_backorder, :weight, :cost_center ]

  def self.datatable_columns
    ['id', 'name', 'sku', 'stock', 'allow_backorder']
  end

  def apply_upcase_to_sku
    self.sku = self.sku.upcase
  end

  def no_fulfillment_related?
    fulfillments.first.nil?
  end

  def validate_sku_update
    if sku_changed? and not no_fulfillment_related?
      errors.add :sku, "Cannot change this sku. There are fulfillments related to it."
      false
    end
  end

  def decrease_stock(quantity=1)
    if self.reload.has_stock?
      Product.where(id: self.id).update_all "stock = stock - #{quantity}"
      logger.info "Product ID: #{self.id} Stock decreased to: #{stock-quantity}"
      {:message => "Stock reduced with success", :code => Settings.error_codes.success}
    else
      {:message => I18n.t('error_messages.product_out_of_stock'), :code => Settings.error_codes.product_out_of_stock}
    end
  end

  def replenish_stock(quantity=1)
    Product.where(id: self.id).update_all "stock = stock + #{quantity}"
    logger.info "Product ID: #{self.id} Stock replenished to: #{stock+quantity}"
  end

  def has_stock?
    allow_backorder? ? true : stock>0
  end

  def self.generate_xls(clubs_id = nil)
    header = ['Name', 'Sku']
    status_list = Fulfillment.state_machines[:status].states.map(&:name)
    status_list.each {|x| header << x}

    package = Axlsx::Package.new
    club_list = Club.where(billing_enable: true)
    club_list = club_list.where(id: clubs_id) if clubs_id 
    club_list.each do |club|
      package.workbook.add_worksheet(:name => club.name) do |sheet|
        sheet.add_row header
        club.products.each do |product|
          row = [ product.name, product.sku ]
          fulfillments_data = product.fulfillments.group(:status).count
          status_list.each {|status| row << (fulfillments_data[status.to_s] || 0) }
          sheet.add_row row
        end
      end
    end
    package
  end

  def self.send_product_list_email(clubs_id = nil)
    product_xls = Product.generate_xls(clubs_id)
    temp = Tempfile.new("posts.xlsx") 
    
    product_xls.serialize temp.path
    Notifier.product_list(temp).deliver_now!
    
    temp.close 
    temp.unlink
  end

  def self.send_bulk_process_results(agent_email, results_file_path)
    Notifier.product_bulk_process_result(results_file_path, agent_email).deliver!
    File.delete(results_file_path)
  end

  def self.bulk_process(club_id, agent_email, file_path)
    package = Axlsx::Package.new
    package.workbook.add_worksheet(:name => 'Results') do |sheet|
      sheet.add_row ['Sku', 'Name', 'Package', 'StockToAdd', 'Allow Backorder', 'Weight', 'Cost Center', 'result']
      CSV.foreach(file_path, headers: true) do |row|
        allow_backorder = row[4]
        sku = row[0].upcase
        new_row = [row[0], row[1], row[2], row[3], row[4], row[5], row[6]]
        if row.count != 7
          new_row << "Wrong number of rows. Review example file."
        elsif allow_backorder.blank? or ['yes','no'].include? allow_backorder.to_s.downcase
          if( row[3].is_numeric? )
            product = Product.where(sku: sku, club_id: club_id).first_or_initialize
            product.name = row[1] unless row[1].blank?
            product.package = row[2] unless row[2].blank?
            product.stock = product.stock.to_i + row[3].to_i
            product.weight = row[5].to_f unless row[5].blank?
            product.cost_center ||= row[6].to_s
            product.cost_center = row[6].to_s unless row[6].blank?
            product.allow_backorder = allow_backorder.to_s.downcase == 'yes' ? true : false
            
            message = if product.new_record?
              'Successfully created.'
            else 
              product.changed? ? "Successfully updated: #{product.changed.join(',')}" : "Nothing was updated."
            end
            
            if product.save
              new_row << message
            else
              message = product.new_record? ? "Could not create product: " : "Could not update product: " 
              message << product.errors.messages.map{|attribute,errors| "#{attribute}: #{errors.join(',')}"}.join(".")
              new_row << message
            end
          else
            new_row << "Stock value is invalid."
          end
        else
          new_row << "Allow backorder value is invalid."
        end
        sheet.add_row new_row
      end
    end
    results_file = File.open("tmp/files/bulk_process_results#{Time.current}.xlsx", 'w')
    package.serialize results_file.path
    results_file.close
    Product.delay.send_bulk_process_results(agent_email, results_file.path)
    File.delete(file_path)
  end
end
