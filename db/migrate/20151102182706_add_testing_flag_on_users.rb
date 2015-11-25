class AddTestingFlagOnUsers < ActiveRecord::Migration
  def change
    add_column :users, :testing_account, :boolean, default: false
  end
end