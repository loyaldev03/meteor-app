  #!/bin/ruby
require 'rubygems'
require 'csv'
require 'rails'
require 'active_record' 

ActiveRecord::Base.configurations["phoenix"] = { 
  :adapter => "mysql2",
  :database => "sac_platform_development",
  :host => "127.0.0.1",
  :username => "root",
  :password => "" 
}

###################################################
##### CLASES ######################################

class DeclineStrategy < ActiveRecord::Base
  establish_connection "phoenix" 
  self.table_name = "decline_strategies" 
end

###################################################
##### METHODS #####################################

def generate_decline_strategies(file)
  file.each do |row|
    ["1.year", "1.month", "1000.years"].each do |installment_type|
      ds = DeclineStrategy.new
      ds.gateway = 'authorize_net'
      ds.installment_type =   
      ds.credit_card_type = "all"
      ds.response_code = row[0]
      ds.notes = row[1]
      ds.decline_type = row[2]
      
      v = row[3].split('*')
      ds.limit = v[0] 
      ds.days = v[1]
      ds.save
    end
  end
end

def init(file_url)
  file_text = File.read(file_url)
  @parsed_file = CSV.parse(file_text, :headers => true)
  generate_decline_strategies(@parsed_file)
end

if ARGV[0].nil?
  puts "Params missing. Provide url of csv file, please"
  exit  
end

file_url = ARGV[0]
init(file_url)