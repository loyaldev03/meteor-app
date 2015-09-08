class Product < ActiveRecord::Base
  belongs_to :club

  validates :sku, :presence => true, :format => /^[0-9a-zA-Z\-_]+$/, :length => { :minimum => 2 }
  validates :cost_center, :format => /^[a-zA-Z\-_]+$/, :length => { :minimum => 2, :maximum => 30 }, :allow_nil => true

  validates :package, :format => /^[a-zA-Z\-_]+$/, :length => { :maximum => 19 }
  validates :stock, :numericality => { :only_integer => true, :less_than => 1999999 }, :allow_backorder => true

  scope :with_stock, where('(allow_backorder = true) OR (allow_backorder = false and stock > 0)')
  scope :not_kit_card, where('sku != "KIT-CARD" ')

  before_save :apply_upcase_to_sku

  def self.datatable_columns
    ['id', 'name', 'recurrent', 'stock', 'weight' ]
  end

  def apply_upcase_to_sku
    self.sku = self.sku.upcase
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

  def self.generate_xls
    header = ['Name', 'Sku']
    status_list = Fulfillment.state_machines[:status].states.map(&:name)
    status_list.each{|x| header << x}

    package = Axlsx::Package.new
    Club.all.each do |club|
      package.workbook.add_worksheet(:name => club.name) do |sheet|
        sheet.add_row header
        club.products.each do |product|
          row = [ product.name, product.sku ]
          status_list.each {|status| row << Fulfillment.joins(:user).where([ "fulfillments.product_sku = ? AND fulfillments.status = ? AND users.club_id = ?", 
                                                product.sku, status.to_s, club.id ]).count }
          sheet.add_row row
        end
      end
    end
    package
  end

  def self.send_product_list_email
    product_xls = Product.generate_xls
    temp = Tempfile.new("posts.xlsx") 
    
    product_xls.serialize temp.path
    Notifier.product_list(temp).deliver!
    
    temp.close 
    temp.unlink
  end 
end
