class ChangeBadEmailToEmailQuality < ActiveRecord::Migration
  def up
    rename_column :prospects, :bad_email, :email_quality
    rename_column :members, :bad_email, :email_quality
  end

  def down
    rename_column :prospects, :email_quality, :bad_email
    rename_column :members, :email_quality, :bad_email
  end
end
