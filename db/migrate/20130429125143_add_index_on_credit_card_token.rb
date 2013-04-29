class AddIndexOnCreditCardToken < ActiveRecord::Migration
  def up
  	execute "ALTER TABLE credit_cards ADD INDEX `index_credit_card_on_token` (`token` ASC);"
  end

  def down
  	execute "DROP INDEX index_credit_card_on_token ON credit_cards"
  end
end
