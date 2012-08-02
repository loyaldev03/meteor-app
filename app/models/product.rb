class Product < ActiveRecord::Base
  belongs_to :club
  
  attr_accessible :club_id, :name, :recurrent, :sku, :stock, :weight

  validates :sku, :uniqueness => true, :presence => true
  validates :stock, :numericality => { :only_integer => true, :greater_than => 0 }

end
