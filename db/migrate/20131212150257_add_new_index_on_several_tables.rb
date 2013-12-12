class AddNewIndexOnSeveralTables < ActiveRecord::Migration
  def up
    execute "ALTER TABLE `clubs` ADD INDEX `index_partner_id` (`partner_id` ASC);"
    execute "ALTER TABLE `clubs` ADD INDEX `index_drupal_domain_id` (`drupal_domain_id` ASC);"
    execute "ALTER TABLE `domains` ADD INDEX `index_club_id` (`club_id` ASC);"
    execute "ALTER TABLE `email_templates` ADD INDEX `index_terms_of_membership_id` (`terms_of_membership_id` ASC);"
    execute "ALTER TABLE `enrollment_infos` ADD INDEX `index_terms_of_membership_id` (`terms_of_membership_id` ASC);"
    execute "ALTER TABLE `member_notes` ADD INDEX `index_created_by_id` (`created_by_id` ASC);"
    execute "ALTER TABLE `memberships` ADD INDEX `index_terms_of_membership_id` (`terms_of_membership_id` ASC);"
    execute "ALTER TABLE `payment_gateway_configurations` ADD INDEX `index_club_id` (`club_id` ASC);"
    execute "ALTER TABLE `terms_of_memberships` ADD INDEX `index_club_id` (`club_id` ASC);"
  end

  def down
  	execute "DROP INDEX index_partner_id ON clubs"
  	execute "DROP INDEX index_drupal_domain_id ON clubs"
  	execute "DROP INDEX index_club_id ON domains"
  	execute "DROP INDEX index_terms_of_membership_id ON email_templates"
  	execute "DROP INDEX index_terms_of_membership_id ON enrollment_infos"
  	execute "DROP INDEX index_created_by_id ON member_notes"
  	execute "DROP INDEX index_terms_of_membership_id ON memberships"
  	execute "DROP INDEX index_club_id ON payment_gateway_configurations"
  	execute "DROP INDEX index_club_id ON terms_of_memberships"
  end
end
