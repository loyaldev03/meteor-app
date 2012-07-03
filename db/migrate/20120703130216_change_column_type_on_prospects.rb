class ChangeColumnTypeOnProspects < ActiveRecord::Migration
  def up
  	change_column :prospects, :user_agent, :string
  end 
  
  def down
  	change_column :prospects, :user_agent, :integer
  end
end
