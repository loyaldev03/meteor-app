class AddCheckoutUrlOnClub < ActiveRecord::Migration
  def change
    add_column :clubs, :checkout_url, :string
  end
end
