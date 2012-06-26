class AddDaysAfterJoinDateOnEmailTemplates < ActiveRecord::Migration
  def up
    add_column :email_templates, :days_after_join_date, :integer, :default => 0
  end

  def down
    remove_column :email_templates, :days_after_join_date
  end
end
