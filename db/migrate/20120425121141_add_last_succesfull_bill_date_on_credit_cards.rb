class AddLastSuccesfullBillDateOnCreditCards < ActiveRecord::Migration
  def up
    add_column :credit_cards, :last_successful_bill_date, :datetime
    add_column :transactions, :credit_card_id, :integer, :limit => 8
  end

  def down
    remove_column :credit_cards, :last_successful_bill_date
    remove_column :transactions, :credit_card_id
  end
end
