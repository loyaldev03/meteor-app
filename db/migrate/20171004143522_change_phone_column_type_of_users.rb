class ChangePhoneColumnTypeOfUsers < ActiveRecord::Migration
  def up
    change_table :users do |t|
      t.change :phone_country_code, :string, limit: 5
      t.change :phone_area_code,    :string, limit: 10
      t.change :phone_local_number, :string, limit: 10
    end
end

  def down
    change_table :users do |t|
      t.change :phone_country_code, :integer
      t.change :phone_area_code,    :integer
      t.change :phone_local_number, :integer
    end
  end
end
