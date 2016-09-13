class FixUnsignedAtributes < ActiveRecord::Migration
  def up
    execute "ALTER TABLE club_cash_transactions MODIFY COLUMN member_id BIGINT(20) UNSIGNED;"
    execute "ALTER TABLE communications MODIFY COLUMN member_id BIGINT(20) UNSIGNED;"
    execute "ALTER TABLE credit_cards MODIFY COLUMN member_id BIGINT(20) UNSIGNED;"
  	execute "ALTER TABLE enrollment_infos MODIFY COLUMN member_id BIGINT(20) UNSIGNED;"
    execute "ALTER TABLE enrollment_infos MODIFY COLUMN membership_id BIGINT(20) UNSIGNED;"
    execute "ALTER TABLE fulfillments MODIFY COLUMN member_id BIGINT(20) UNSIGNED;"
    execute "ALTER TABLE member_notes MODIFY COLUMN member_id BIGINT(20) UNSIGNED;"
    execute "ALTER TABLE member_preferences MODIFY COLUMN member_id BIGINT(20) UNSIGNED;"
    execute "ALTER TABLE members MODIFY COLUMN id BIGINT(20) UNSIGNED NOT NULL AUTO_INCREMENT;"
    execute "ALTER TABLE members MODIFY COLUMN current_membership_id BIGINT(20) UNSIGNED;"
    execute "ALTER TABLE memberships MODIFY COLUMN member_id BIGINT(20) UNSIGNED;"
    execute "ALTER TABLE operations MODIFY COLUMN member_id BIGINT(20) UNSIGNED;"
    execute "ALTER TABLE transactions MODIFY COLUMN member_id BIGINT(20) UNSIGNED;"
    execute "ALTER TABLE transactions MODIFY COLUMN membership_id BIGINT(20) UNSIGNED;"
  end

  def down
    execute "ALTER TABLE club_cash_transactions MODIFY COLUMN member_id BIGINT(20);"
    execute "ALTER TABLE communications MODIFY COLUMN member_id BIGINT(20);"
    execute "ALTER TABLE credit_cards MODIFY COLUMN member_id BIGINT(20);"
  	execute "ALTER TABLE enrollment_infos MODIFY COLUMN member_id BIGINT(20);"
    execute "ALTER TABLE enrollment_infos MODIFY COLUMN membership_id BIGINT(20);"
    execute "ALTER TABLE fulfillments MODIFY COLUMN member_id BIGINT(20);"
    execute "ALTER TABLE member_notes MODIFY COLUMN member_id BIGINT(20);"
    execute "ALTER TABLE member_preferences MODIFY COLUMN member_id BIGINT(20);"
    execute "ALTER TABLE members MODIFY COLUMN id BIGINT(20);"
    execute "ALTER TABLE members MODIFY COLUMN current_membership_id BIGINT(20);"
    execute "ALTER TABLE memberships MODIFY COLUMN member_id BIGINT(20);"
    execute "ALTER TABLE operations MODIFY COLUMN member_id BIGINT(20);"
    execute "ALTER TABLE transactions MODIFY COLUMN member_id BIGINT(20);"
    execute "ALTER TABLE transactions MODIFY COLUMN membership_id BIGINT(20);"
  end
end
