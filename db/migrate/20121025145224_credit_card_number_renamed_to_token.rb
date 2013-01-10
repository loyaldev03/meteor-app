class CreditCardNumberRenamedToToken < ActiveRecord::Migration
  def up
    remove_column :credit_cards, :encrypted_number
    remove_column :transactions, :encrypted_number
    add_column :credit_cards, :token, :string
    add_column :transactions, :token, :string
  end

  def down
    add_column :credit_cards, :encrypted_number, :string
    add_column :transactions, :encrypted_number, :string
    remove_column :credit_cards, :token
    remove_column :transactions, :token
  end
end
