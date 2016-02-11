class AddSomeImprovementsOnSeveralTables < ActiveRecord::Migration
  def change
    change_column :enumerations, :type, :string, limit: 40 
    change_column :partners, :prefix, :string, limit: 40

    add_index :partners, :prefix
    add_index :products, :club_id
    add_index :enumerations, [:visible, :type]
  end
end
