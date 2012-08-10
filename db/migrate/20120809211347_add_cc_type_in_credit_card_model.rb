class AddCcTypeInCreditCardModel < ActiveRecord::Migration
  def change
    add_column :credit_cards, :cc_type, :string
  end
end
