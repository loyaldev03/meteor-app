class Product < ActiveRecord::Base
  belongs_to :club

  attr_accessible :name, :recurrent, :sku, :stock, :weight

  validates :sku, :uniqueness => true, :presence => true
  validates :stock, :numericality => { :only_integer => true, :greater_than => 0 }
  validates :sku, :format => /^[a-zA-Z -_]+$/


  def self.datatable_columns
    ['id', 'name', 'recurrent', 'stock', 'weight', 'created_at' ]
  end


end
