class ModifyColumnHostedOnDomains < ActiveRecord::Migration
  def up
	change_column_default(:domains,:hosted,false)
  end

  def down
	change_column_default(:domains,:hosted,nil)   	
  end
end
