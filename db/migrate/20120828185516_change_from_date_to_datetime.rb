class ChangeFromDateToDatetime < ActiveRecord::Migration
  def up
    add_column :clubs, :time_zone, :string, :limit => 255, :default => "UTC"
    change_column :members, :cancel_date, :datetime
    change_column :members, :bill_date, :datetime
    change_column :members, :next_retry_bill_date, :datetime
    change_column :members, :email_unsubscribed_at, :datetime
    change_column :members, :club_cash_expire_date, :datetime
  end

  def down
    remove_column :clubs, :time_zone
    change_column :members, :cancel_date, :date
    change_column :members, :bill_date, :date
    change_column :members, :next_retry_bill_date, :date
    change_column :members, :email_unsubscribed_at, :date
    change_column :members, :club_cash_expire_date, :date
  end
end
