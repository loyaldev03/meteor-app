class RenameColumnDaysAfterJoinDateToDays < ActiveRecord::Migration
  def up
    rename_column :email_templates, :days_after_join_date, :days
    execute "UPDATE email_templates SET days = 7 WHERE template_type = 'prebill'"
  end

  def down
    rename_column :email_templates, :days, :days_after_join_date
    execute "UPDATE email_templates SET days_after_join_date = 0 WHERE template_type = 'prebill'"
  end
end
