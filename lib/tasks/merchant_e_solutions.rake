require 'aus_gateways/mes_account_updater'

namespace :mes do
  
  desc "get chargeback report"
  task :chargeback_report => :environment do
    Rails.logger = Logger.new("#{Rails.root}/log/mes_process_chargebacks.log")
    Rails.logger.level = Logger::DEBUG
    ActiveRecord::Base.logger = Rails.logger

    mode = (Rails.env == 'production' ? 'production' : 'development')
    MesAccountUpdater.process_chargebacks(mode)
  end

  desc "Send file to account updater. ONMC version"
  task :account_updater_process_answers => :environment do
    Rails.logger = Logger.new("#{Rails.root}/log/mes_account_updater_process_answers.log")
    Rails.logger.level = Logger::DEBUG
    ActiveRecord::Base.logger = Rails.logger

    mode = (Rails.env == 'production' ? 'production' : 'development')
    MesAccountUpdater.account_updater_process_answers(mode)
  end

  desc "Send file to account updater. ONMC version"
  task :account_updater_send_file_to_process => :environment do
    Rails.logger = Logger.new("#{Rails.root}/log/mes_account_updater_send_file_to_process.log")
    Rails.logger.level = Logger::DEBUG
    ActiveRecord::Base.logger = Rails.logger

    mode = (Rails.env == 'production' ? 'production' : 'development')
    MesAccountUpdater.account_updater_send_file_to_process(mode)
  end

end