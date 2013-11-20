class AddIndexOnSeveralForImprovementPerformance < ActiveRecord::Migration
  def up
  	execute "ALTER TABLE `club_cash_transactions` ADD INDEX `index_member_id` (`member_id` ASC);"
  	execute "ALTER TABLE `member_notes` ADD INDEX `index_member_id` (`member_id` ASC);"
  	execute "ALTER TABLE `fulfillment_files_fulfillments` ADD INDEX `index_fulfillment_file_id` (`fulfillment_file_id` ASC);"
  end

  def down
  	execute "DROP INDEX index_member_id ON club_cash_transactions"
  	execute "DROP INDEX index_member_id ON member_notes"
  	execute "DROP INDEX index_fulfillment_file_id ON fulfillment_files_fulfillments"
  end
end