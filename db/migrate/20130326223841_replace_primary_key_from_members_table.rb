class ReplacePrimaryKeyFromMembersTable < ActiveRecord::Migration
  def up
    [ 'club_cash_transactions', 'communications', 'credit_cards', 'enrollment_infos', 
      'fulfillments', 'member_notes', 'member_preferences', 'memberships', 'operations', 'transactions' ].each do |table|
      execute "ALTER TABLE #{table} ADD COLUMN member_id_new BIGINT(20);"
      execute "UPDATE #{table}, members SET member_id_new = members.visible_id WHERE members.uuid = #{table}.member_id;"
      execute "ALTER TABLE #{table} DROP COLUMN member_id;"
      execute "ALTER TABLE #{table} CHANGE member_id_new member_id BIGINT(20);"
    end
    
    execute "ALTER TABLE members DROP COLUMN uuid;"
    execute "ALTER TABLE members CHANGE COLUMN visible_id id BIGINT(20) UNSIGNED NOT NULL AUTO_INCREMENT, DROP PRIMARY KEY, ADD PRIMARY KEY (id);"
  end

  def down
  end
end
