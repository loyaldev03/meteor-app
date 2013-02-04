class AddFamilyMembershipsAllowedAtClubs < ActiveRecord::Migration
  def change
    add_column :clubs, :family_memberships_allowed, :boolean, :default => false
  end
end
