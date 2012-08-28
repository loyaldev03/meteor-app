class Product < ActiveRecord::Base
  belongs_to :club

  attr_accessible :name, :recurrent, :sku, :stock, :weight

  validates :sku, :uniqueness => {:scope => :club_id}, :presence => true
  validates :stock, :numericality => { :only_integer => true, :greater_than_or_equal_to => 0, :less_than => 1999999}
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

  def decrease_stock(quantity=1)
    self.stock = self.stock-quantity
    self.save 
  end

  def has_stock?
    stock > 0
  end

end
