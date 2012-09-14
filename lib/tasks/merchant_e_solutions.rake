namespace :mes do
  desc "get chargeback report"
  task :chargeback_report => :environment do
    mode = (Rails.env == 'production' ? 'production' : 'development')
    PaymentGatewayConfiguration.process_mes_chargebacks(mode)
  end

  desc "Send file to account updater. ONMC version"
  task :account_updater_process_answers => :environment do
    mode = (Rails.env == 'production' ? 'production' : 'development')
    PaymentGatewayConfiguration.account_updater_process_answers(mode)
  end

  desc "Send file to account updater. ONMC version"
  task :account_updater_send_file_to_process => :environment do
    mode = (Rails.env == 'production' ? 'production' : 'development')
    PaymentGatewayConfiguration.account_updater_send_file_to_process(mode)
  end


end