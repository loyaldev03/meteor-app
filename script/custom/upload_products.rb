  #!/bin/ruby
require 'rubygems'
require 'rails'
require 'active_record' 
require 'csv'    

ActiveRecord::Base.configurations["phoenix"] = { 
  :adapter => "mysql2",
  :database => "sac_platform_development",
  :host => "127.0.0.1",
  :username => "root",
  :password => "" 
}

###################################################
##### CLASES ######################################

class Product < ActiveRecord::Base
  establish_connection "phoenix" 
  self.table_name = "products" 
end

###################################################
##### METHODS #####################################

  def generate_products(file, club_id)
    file.each  do |row|
      product = Product.find_by_sku_and_club_id row[2], club_id
      if product.nil?   #Product does not already exists?
        product = Product.new
        product.sku = row[2]
        product.club_id = club_id
      end
      product.name = row[0] 
      product.package = row[1]
      product.recurrent = (row[3].upcase=='YES' ? true : false )
      product.stock = row[4].to_i
      product.weight = row[5].to_i
      product.allow_backorder = (row[6].upcase=='YES' ? true : false )
      product.cost_center = row[7]
      product.save
    end
  end

  def init(file_url, club_id)
    file_text = File.read(file_url)
    @parsed_file = CSV.parse(file_text, :headers => true)
    generate_products(@parsed_file, club_id)
  end

  file_url= ARGV[0]
  club_id = ARGV[1].to_i
  
  if ARGV[0].nil? or ARGV[1].nil?
    puts "Way to use:     $ruby upload_products.rb 'csv file' 'club id'"
    exit
  end
  init(file_url,club_id)
