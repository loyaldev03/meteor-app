namespace :mes do
  desc "get chargeback report"
  task :chargeback_report => :environment do
    mode = (Rails.env == 'production' ? 'production' : 'development')
    PaymentGatewayConfiguration.process_mes_chargebacks(mode)
  end

  desc "Send file to account updater. ONMC version"
  task :account_updater_send_file => :environment do
    # TODO:
  end


end