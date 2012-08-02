class Product < ActiveRecord::Base
  attr_accessible :club_id, :name, :recurrent, :sku, :stock, :weight

  validates :sku, :uniqueness => true, :presence => true
  validates :stock, :numericality => { :only_integer => true, :greater_than => 0 }
  validates :sku, :format => /^[a-zA-Z -_]$/
end
