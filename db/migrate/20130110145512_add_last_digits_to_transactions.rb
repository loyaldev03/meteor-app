class AddLastDigitsToTransactions < ActiveRecord::Migration
  def change
    add_column :transactions, :last_digits, :string
  end
end
