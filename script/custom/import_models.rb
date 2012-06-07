require 'rails'
require 'active_record'
require 'uuidtools'
require 'attr_encrypted'

# add phoenix database connection
ActiveRecord::Base.configurations["phoenix"] = { 
  :adapter => "mysql2",
  :database => "sac_platform_development",
  :host => "127.0.0.1",
  :username => "root",
  :password => "" 
}

ActiveRecord::Base.configurations["customer_services"] = { 
  :adapter => "mysql2",
  :database => "onmc_customer_services",
  :host => "127.0.0.1",
  :username => "root",
  :password => "" 
}

ActiveRecord::Base.configurations["billing"] = { 
  :adapter => "mysql2",
  :database => "onmc_billing",
  :host => "127.0.0.1",
  :username => "root",
  :password => "" 
}


class PhoenixMember < ActiveRecord::Base
  establish_connection "phoenix" 
  self.table_name = "members" 
  self.primary_key = 'uuid'
  before_create :generate_uuid
  
  def generate_uuid
    self.id = UUIDTools::UUID.random_create.to_s
  end
end

class PhoenixCreditCard < ActiveRecord::Base
  establish_connection "phoenix" 
  self.table_name = "credit_cards"
  attr_encrypted :number, :key => 'reibel3y5estrada8', :encode => true, :algorithm => 'bf' 
end

class PhoenixOperation < ActiveRecord::Base
  establish_connection "phoenix" 
  self.table_name = "operations" 
end

class BillingMember < ActiveRecord::Base
  establish_connection "billing" 
  self.table_name = "members" # Use "new_members" 
end
