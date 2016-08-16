class AddIndexOnFulfillmentsOnColumnsClubIdAssignedAtAndStatus < ActiveRecord::Migration
  def change
    add_index :fulfillments, [:club_id, :assigned_at, :status]
  end
end
