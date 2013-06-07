class AddOperationTypeOnTransactionModel < ActiveRecord::Migration
	def up
		add_column :transactions, :operation_type, :integer
	end

	def down
		remove_column :transactions, :operation_type
	end
end