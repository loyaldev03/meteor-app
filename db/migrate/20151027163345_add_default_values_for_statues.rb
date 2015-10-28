class AddDefaultValuesForStatues < ActiveRecord::Migration
  def change
    change_column :users, :status, :string,               default: 'none'
    change_column :fulfillments, :status, :string,        default: 'not_processed'
    change_column :fulfillment_files, :status, :string,   default: 'in_process'
  end
end
