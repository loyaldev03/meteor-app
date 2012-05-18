class AddDrupalIdToMembers < ActiveRecord::Migration
  def change
    change_table :members do |t|
      t.integer :drupal_id
    end
  end
end
