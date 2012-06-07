class ChangeSomeColumnsTypeOnProspect < ActiveRecord::Migration
  def up
  	remove_column :prospects, :birth_date
    add_column :prospects, :birth_date, :date
  	remove_column :prospects, :preferences
    add_column :prospects, :preferences, :text
  	remove_column :prospects, :referral_parameters
    add_column :prospects, :referral_parameters, :text
  	remove_column :prospects, :cookie_value
    add_column :prospects, :cookie_value, :text
  end

  def down
  	remove_column :prospects, :birth_date
    add_column :prospects, :birth_date, :datetime
  	remove_column :prospects, :preferences
    add_column :prospects, :preferences, :string
  	remove_column :prospects, :referral_parameters
    add_column :prospects, :referral_parameters, :string
  	remove_column :prospects, :cookie_value
    add_column :prospects, :cookie_value, :string
  end
end
