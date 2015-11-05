class Product < ActiveRecord::Base
  belongs_to :club

  validates :sku, :presence => true, :format => /^[0-9a-zA-Z\-_]+$/, :length => { :minimum => 2 }, :uniqueness => { scope: [:club_id, :deleted_at] }
  validates :cost_center, :format => /^[a-zA-Z\-_]+$/, :length => { :minimum => 2, :maximum => 30 }, :allow_nil => true

  validates :package, :format => /^[a-zA-Z\-_]+$/, :length => { :maximum => 19 }
  validates :stock, :numericality => { :only_integer => true, :less_than => 1999999 }, :allow_backorder => true

  scope :with_stock, where('(allow_backorder = true) OR (allow_backorder = false and stock > 0)')
  scope :not_kit_card, where('sku != "KIT-CARD" ')

  before_save :apply_upcase_to_sku
  before_update :validate_sku_update
  before_destroy :any_fulfillment_related?

  acts_as_paranoid

  def self.datatable_columns
    ['id', 'name', 'sku', 'stock', 'allow_backorder' ]
  end

  def apply_upcase_to_sku
    self.sku = self.sku.upcase
  end

  def any_fulfillment_related?
    Fulfillment.where(club_id: self.club_id, product_sku: self.sku).limit(1).empty?
  end

  def validate_sku_update
    if sku_changed? and Fulfillment.where(club_id: self.club_id, product_sku: self.sku_was).limit(1).any?
      errors.add :sku, "Cannot change this sku. There are fulfillments related to it."
      false
    end
  end

  def update_product_data_by_params(params)
  	self.name = params[:name]
  	self.recurrent = params[:recurrent]
  	self.sku = params[:sku]
    self.package = params[:package]
  	self.stock = params[:stock]
  	self.weight = params[:weight]
    self.cost_center = params[:cost_center]
    self.allow_backorder = params[:allow_backorder]
    self.is_visible = params[:is_visible]
  end

  def decrease_stock(quantity=1)
    Product.where(id: self.id).update_all "stock = stock - #{quantity}"
  end

  def replenish_stock(quantity=1)
    self.stock = self.stock+quantity
    self.save
  end

  def has_stock?
    allow_backorder? ? true : stock>0
  end

  def self.generate_xls(clubs_id = nil)
    header = ['Name', 'Sku']
    status_list = Fulfillment.state_machines[:status].states.map(&:name)
    status_list.each{|x| header << x}

    package = Axlsx::Package.new
    club_list = Club.where(billing_enable: true)
    club_list = club_list.where(id: clubs_id) if clubs_id 
    club_list.each do |club|
      package.workbook.add_worksheet(:name => club.name) do |sheet|
        sheet.add_row header
        club.products.each do |product|
          row = [ product.name, product.sku ]
          fulfillments_data = Fulfillment.where(product_sku: product.sku, club_id: club.id).group(:status).count
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
    Notifier.product_list(temp).deliver!
    
    temp.close 
    temp.unlink
  end

  def self.send_bulk_update_results(agent_email, results_file_path)
    Notifier.product_bulk_update_result(results_file_path, agent_email).deliver!
    File.delete(results_file_path)
  end

  def self.bulk_update(club_id, agent_email, file_path)
    package = Axlsx::Package.new
    package.workbook.add_worksheet(:name => 'Results') do |sheet|
      sheet.add_row ['sku', 'stock', 'allow_backorder', 'result']
      CSV.foreach(file_path, headers: true) do |row|
        sku, stock, allow_backorder = row[0], row[1], row[2]
        product = Product.where(sku: sku, club_id: club_id).first
        new_row = [sku, stock, allow_backorder]
        if product 
          if ['yes','no'].include? allow_backorder
            product.stock = stock unless stock.blank?
            product.allow_backorder = allow_backorder=='yes' ? true : false
            if product.save 
              new_row << 'Updated successfully.'
            else
              new_row << product.errors.messages.map{|attribute,errors| "#{attribute}: #{errors.join(',')}"}.join(".")
            end
          else
            new_row << "Allow backorder value is invalid."       
          end
        else 
          new_row << "Product not found."
        end
        sheet.add_row new_row
      end
    end
    results_file = File.open("tmp/bulk_update_results#{Time.current}.xlsx", 'w')
    package.serialize results_file.path
    results_file.close
    Product.delay.send_bulk_update_results(agent_email, results_file.path)
    File.delete(file_path)
  end
end