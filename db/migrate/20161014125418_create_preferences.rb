class CreatePreferences < ActiveRecord::Migration
  def change
    create_table :preferences do |t|
      t.string :name
      t.references :preference_group

      t.timestamps null: false
    end

  end
end