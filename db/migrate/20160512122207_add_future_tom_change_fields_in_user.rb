class AddFutureTomChangeFieldsInUser < ActiveRecord::Migration
  def change
    add_column :users, :change_tom_date, :date
    add_column :users, :change_tom_attributes, :text
  end
end
