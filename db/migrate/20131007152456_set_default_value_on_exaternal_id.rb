class SetDefaultValueOnExaternalId < ActiveRecord::Migration
  def up
    change_column :members, :external_id, :string, :default => ''
  end

  def down
    change_column :members, :external_id, :string, :default => nil
  end
end
