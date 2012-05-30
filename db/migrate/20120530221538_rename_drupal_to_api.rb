class RenameDrupalToApi < ActiveRecord::Migration
  def up
    add_column :clubs, :api_type, :string, :default => 'Drupal::Member'
    rename_column :members, :drupal_id, :api_id
    rename_column :clubs, :drupal_username, :api_username
    rename_column :clubs, :drupal_password, :api_password
  end

  def down
    remove_column :clubs, :api_type
    rename_column :members, :api_id, :drupal_id
    rename_column :clubs, :api_username, :drupal_username
    rename_column :clubs, :api_password, :drupal_password
  end
end
