class AddLastDigitsToCreditCards < ActiveRecord::Migration
  def up
    add_column :credit_cards, :last_digits, :string, :limit => 4
  end

  def down
  	remove_column :credit_cards, :last_digits
  end
end
