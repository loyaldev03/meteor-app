class CreatePreferenceGroups < ActiveRecord::Migration
  def change
    create_table :preference_groups do |t|
      t.string :name
      t.string :code
      t.boolean :add_by_default
      t.references :club

      t.timestamps null: false
    end

    add_index :preference_groups, :club_id

    create_table :campaigns_preference_groups, id: false do |t|
      t.references :preference_group
      t.references :campaign
    end

    add_index :campaigns_preference_groups, :preference_group_id
    add_index :campaigns_preference_groups, :campaign_id
  end
end