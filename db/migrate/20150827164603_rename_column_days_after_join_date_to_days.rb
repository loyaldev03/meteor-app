class RenameColumnDaysAfterJoinDateToDays < ActiveRecord::Migration
  def up
    rename_column :email_templates, :days_after_join_date, :days
  end

  def down
    rename_column :email_templates, :days, :days_after_join_date
  end
end
