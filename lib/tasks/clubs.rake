namespace :clubs do
  desc "Count members in clubs"
  # This task should be run every X hours. 
  task :count_members_in_clubs => :environment do
    Rails.logger = Logger.new("#{Rails.root}/log/count_members_in_clubs.log")
    Rails.logger.level = Logger::DEBUG
    ActiveRecord::Base.logger = Rails.logger
    tall = Time.zone.now
    begin
      clubs = Club.all
      clubs.map do |club|
        club.update_attribute(:members_count, club.members.count + 0)
      end
    ensure 
      Rails.logger.info "It all took #{Time.zone.now - tall} to run clubs:count_members_in_clubs task"
    end 
  end
end
