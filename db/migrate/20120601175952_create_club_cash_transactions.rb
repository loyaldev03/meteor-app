class CreateClubCashTransactions < ActiveRecord::Migration
  def up
  	create_table :club_cash_transactions do |t|
      t.string   :member_id
      t.decimal  :amount, :default => 0.0      
      t.text     :description
    end
  end

  def down
  	drop_table :club_cash_transactions
  end
end
