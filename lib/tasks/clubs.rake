namespace :clubs do
  desc "Count users in clubs"
  # This task should be run every X hours. 
  task :count_users_in_clubs => :environment do
    Rails.logger = Logger.new("#{Rails.root}/log/count_members_in_clubs.log")
    Rails.logger.level = Logger::DEBUG
    ActiveRecord::Base.logger = Rails.logger
    tall = Time.zone.now
    begin
      Club.all.each do |club|
        club.update_attribute(:users_count, club.users.count + 0)
      end
    rescue Exception => e
      Auditory.report_issue("Clubs::count_users_in_clubs", e, {:backtrace => "#{$@[0..9] * "\n\t"}"})
      Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"      
    ensure 
      Rails.logger.info "It all took #{Time.zone.now - tall}seconds to run clubs:count_users_in_clubs task"
    end 
  end
end
