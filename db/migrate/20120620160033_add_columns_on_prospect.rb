class AddColumnsOnProspect < ActiveRecord::Migration
  def up
    add_column :prospects, :club_id, :integer, :limit => 8
    add_column :prospects, :country, :string
    add_column :prospects, :terms_of_membership_id, :integer, :limit => 8
  end

  def down
    remove_column :prospects, :club_id
    remove_column :prospects, :country
    remove_column :prospects, :terms_of_membership_id
  end
end
