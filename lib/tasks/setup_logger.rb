task :setup_logger do |t|
  Rails.logger = Logger.new("#{Rails.root}/log/#{t.application.top_level_tasks.first.split(':')[1]}.log")
  Rails.logger.level = Logger::DEBUG
  ActiveRecord::Base.logger = Rails.logger
  Rails.logger.info " *** [#{I18n.l(Time.zone.now)}] Starting rake task"
end