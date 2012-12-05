class AddIndexes < ActiveRecord::Migration
  def change
    add_index :transactions, :member_id
  end

end
