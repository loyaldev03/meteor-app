class ChangePhoneColumnTypeOfUsers < ActiveRecord::Migration
  def up
    change_table :users do |t|
      t.change :phone_country_code, :string, limit: 5
      t.change :phone_area_code,    :string, limit: 10
      t.change :phone_local_number, :string, limit: 10
    end
    User.find_each do |user|
      user.update_columns(
        phone_country_code: format('%03d', user.phone_country_code.to_i),
        phone_area_code:    format('%03d', user.phone_area_code.to_i),
        phone_local_number: format('%07d', user.phone_local_number.to_i)
      )
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
