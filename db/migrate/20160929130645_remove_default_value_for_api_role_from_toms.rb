class RemoveDefaultValueForApiRoleFromToms < ActiveRecord::Migration
  def up
    change_column_default(:terms_of_memberships, :api_role, nil)
  end
  def down
    change_column_default(:terms_of_memberships, :api_role, '91284557')
  end
end
