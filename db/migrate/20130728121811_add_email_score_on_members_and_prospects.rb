class AddEmailScoreOnMembersAndProspects < ActiveRecord::Migration
  def up
    add_column :prospects, :bad_email, :integer, :default => 0
    add_column :members, :bad_email, :integer, :default => 0
  end

  def down
    remove_column :prospects, :bad_email
    remove_column :members, :bad_email
  end
end
