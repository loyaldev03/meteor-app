class ProspectApiUpdates < ActiveRecord::Migration
  def change
    add_column :prospects, :type_of_phone_number, :string
    add_column :prospects, :gender, :string
  end
end
