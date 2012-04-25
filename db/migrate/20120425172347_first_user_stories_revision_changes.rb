class FirstUserStoriesRevisionChanges < ActiveRecord::Migration
  def up
    add_column :operations, :notes, :text
    remove_column :members, :work_phone
    remove_column :members, :home_phone
    add_column :members, :phone_number, :string
    add_column :members, :wrong_address, :integer
    add_column :members, :wrong_phone_number, :integer
  end

  def down
    remove_column :operations, :notes
    add_column :members, :work_phone
    add_column :members, :home_phone
    remove_column :members, :phone_number
    remove_column :members, :wrong_address
    remove_column :members, :wrong_phone_number
  end
end
