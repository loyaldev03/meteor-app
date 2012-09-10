class AddMesAusColumnsOnMember < ActiveRecord::Migration
  def up
    add_column :members, :aus_answered_at, :datetime
    add_column :members, :aus_status, :string
  end

  def down
  end
end
