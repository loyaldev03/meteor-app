class AddMesAusColumnsOnMember < ActiveRecord::Migration
  def up
    add_column :credit_cards, :aus_sent_at, :datetime
    add_column :credit_cards, :aus_answered_at, :datetime
    add_column :credit_cards, :aus_status, :string
  end

  def down
    remove_column :credit_cards, :aus_sent_at
    remove_column :credit_cards, :aus_answered_at
    remove_column :credit_cards, :aus_status
  end
end
