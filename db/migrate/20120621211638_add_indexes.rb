class AddIndexes < ActiveRecord::Migration
  def change
    add_index :members, :uuid
    add_index :credit_cards, :member_id
    add_index :member_notes, :member_id
    add_index :operations, :member_id
    add_index :members, :email
  end
end
