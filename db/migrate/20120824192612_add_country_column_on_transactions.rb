class AddCountryColumnOnTransactions < ActiveRecord::Migration
  def up
  	add_column :transactions, :country, :string 
  end

  def down
  	remove_column :transactions, :country
  end
end
