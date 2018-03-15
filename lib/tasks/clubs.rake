namespace :clubs do
  desc "Count users in clubs"
  # This task should be run every X hours. 
  task :count_members_in_clubs => :environment do
    Rails.logger = Logger.new("#{Rails.root}/log/count_members_in_clubs.log")
    Rails.logger.level = Logger.const_get(Settings.logger_level_for_tasks)
    ActiveRecord::Base.logger = Rails.logger
    tall = Time.zone.now
    begin
      Club.where(billing_enable: true).each do |club|
        club.update_attribute(:members_count, club.users.count + 0)
      end
    ensure 
      Rails.logger.info "It all took #{Time.zone.now - tall}seconds to run clubs:count_members_in_clubs task"
    end 
  end
end
