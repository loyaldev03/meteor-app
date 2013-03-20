class Product < ActiveRecord::Base
  belongs_to :club

  attr_accessible :name, :recurrent, :sku, :stock, :weight, :package, :allow_backorder, :cost_center

  validates :sku, :uniqueness => {:scope => :club_id}, :presence => true, :format => /^[0-9a-zA-Z\-_]+$/, :length => { :minimum => 2 }
  validates :cost_center, :format => /^[a-zA-Z\-_]+$/, :length => { :minimum => 2, :maximum => 30 }, :allow_nil => true

  validates :package, :format => /^[a-zA-Z\-_]+$/, :length => { :maximum => 19 }
  validates :stock, :numericality => { :only_integer => true, :less_than => 1999999 }, :allow_backorder => true

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
  end

  def decrease_stock(quantity=1)
    self.stock = self.stock-quantity
    self.save 
  end

  def has_stock?
    allow_backorder? ? true : stock>0
  end

  def self.generate_xls
    header = ['Name', 'Sku']
    status_list = Fulfillment.state_machines[:status].states.map(&:name).select {|x| x != :sent }
    status_list.each{|x| header << x}

    package = Axlsx::Package.new
    Club.all.each do |club|
      package.workbook.add_worksheet(:name => club.name) do |sheet|
        sheet.add_row header
        club.products.each do |product|
          row = [ product.name, product.sku ]
          status_list.each {|status| row << Fulfillment.joins(:member).where([ "fulfillments.product_sku = ? AND fulfillments.status = ? AND members.club_id = ?", 
                                                product.sku, status.to_s, club.id ]).count }
          sheet.add_row row
        end
      end
    end
    package
  end

end
