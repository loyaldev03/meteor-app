class ChangeMemberToUser < ActiveRecord::Migration
  def up
    rename_table :members, :users
    rename_table :member_additional_data, :user_additional_data
    rename_table :member_notes, :user_notes
    rename_table :member_preferences, :user_preferences
    rename_column :club_cash_transactions, :member_id, :user_id
    rename_column :communications, :member_id, :user_id
    rename_column :credit_cards, :member_id, :user_id
    rename_column :enrollment_infos, :user_id, :visitor_id
    rename_column :enrollment_infos, :member_id, :user_id
    rename_column :fulfillments, :member_id, :user_id
    rename_column :user_additional_data, :member_id, :user_id
    rename_column :user_notes, :member_id, :user_id
    rename_column :user_preferences, :member_id, :user_id
    rename_column :memberships, :member_id, :user_id
    rename_column :operations, :member_id, :user_id
    rename_column :transactions, :member_id, :user_id
    rename_column :prospects, :user_id, :visitor_id
    rename_column :clubs, :members_count, :users_count
  end

  def down
    rename_table :users, :members
    rename_table :user_additional_data, :member_additional_data
    rename_table :user_notes, :member_notes
    rename_table :user_preferences, :member_preferences
    rename_column :club_cash_transactions, :user_id, :member_id
    rename_column :communications, :user_id, :member_id
    rename_column :credit_cards, :user_id, :member_id
    rename_column :enrollment_infos, :user_id, :member_id
    rename_column :enrollment_infos, :visitor_id, :user_id
    rename_column :fulfillments, :user_id, :member_id
    rename_column :member_additional_data, :user_id, :member_id
    rename_column :member_notes, :user_id, :member_id
    rename_column :member_preferences, :user_id, :member_id
    rename_column :memberships, :user_id, :member_id
    rename_column :operations, :user_id, :member_id
    rename_column :transactions, :user_id, :member_id
    rename_column :prospects, :visitor_id, :user_id
    rename_column :clubs, :users_count, :members_count
  end
end