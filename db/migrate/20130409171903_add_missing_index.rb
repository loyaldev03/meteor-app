class AddMissingIndex < ActiveRecord::Migration
  def up
  	execute "ALTER TABLE credit_cards ADD INDEX `index2` (`member_id` ASC);"
  	execute "ALTER TABLE memberships ADD INDEX `index2` (`member_id` ASC);"
  	execute "ALTER TABLE fulfillments ADD INDEX `index2` (`member_id` ASC);"
  	execute "ALTER TABLE operations ADD INDEX `index2` (`member_id` ASC);"
  end

  def down
  	execute "DROP INDEX index2 ON credit_cards"
  	execute "DROP INDEX index2 ON memberships"
  	execute "DROP INDEX index2 ON fulfillments"
  	execute "DROP INDEX index2 ON operations"
  end
end
