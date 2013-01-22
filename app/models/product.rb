class Product < ActiveRecord::Base
  belongs_to :club

  attr_accessible :name, :recurrent, :sku, :stock, :weight, :package

  validates :sku, :uniqueness => {:scope => :club_id}, :presence => true, :format => /^[a-zA-Z\-_]+$/, :length => { :minimum => 2, :maximum => 19 }

  validates :package, :format => /^[a-zA-Z\-_]+$/, :length => { :minimum => 2, :maximum => 30 }
  validates :stock, :numericality => { :only_integer => true, :less_than => 1999999}


  def self.datatable_columns
    ['id', 'name', 'recurrent', 'stock', 'weight' ]
  end

  def update_product_data_by_params(params)
  	self.name = params[:name]
  	self.recurrent = params[:recurrent]
  	self.sku = params[:sku]
    self.package = params[:package]
  	self.stock = params[:stock]
  	self.weight = params[:weight]
  end

  def decrease_stock(quantity=1)
    self.stock = self.stock-quantitystt
    self.save 
  end

  def has_stock?
    stock > 0
  end

  def self.generate_xls
    header = ['Name', 'Sku']
    status_list = []
    Fulfillment.state_machines[:status].states.map(&:name).each{|x| status_list << x.to_s unless x.to_s == "sent"}
    status_list.each{|x| header << x}

    package = Axlsx::Package.new
    Club.all.each do |club|
      package.workbook.add_worksheet(:name => club.name) do |sheet|
        sheet.add_row header
        Product.find_all_by_club_id(club.id).each do |product|
          row = []
          row << product.name
          row << product.sku
          status_list.each {|status| row << Fulfillment.where(["product_sku = ? AND member_id IN (?) 
                                                                 AND status = ?", product.sku, 
                                                                 Member.find_all_by_club_id(club.id).map(&:id), 
                                                                 status]).count }
          sheet.add_row row
        end
      end
    end
    package
  end

end
