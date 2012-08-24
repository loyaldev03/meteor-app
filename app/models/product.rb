class Product < ActiveRecord::Base
  belongs_to :club

  attr_accessible :name, :recurrent, :sku, :stock, :weight

  validates :sku, :uniqueness => true, :presence => true
  validates :stock, :numericality => { :only_integer => true, :greater_than => 0 }
  validates :sku, :format => /^[a-zA-Z\-_]+$/


  def self.datatable_columns
    ['id', 'name', 'recurrent', 'stock', 'weight' ]
  end

  def update_product_data_by_params(params)
  	self.name = params[:name]
  	self.recurrent = params[:recurrent]
  	self.sku = params[:sku]
  	self.stock = params[:stock]
  	self.weight = params[:weight]
  end

  def decrease_stock(quantity)
    self.stock = self.stock-quantity
    self.save 
  end

  def check_if_there_is_stock_left
    self.stock>0 ? true : false
  end

end
