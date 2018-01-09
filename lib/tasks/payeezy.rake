require 'aus_gateways/payeezy_account_updater'

namespace 'payeezy' do
  desc 'get chargeback report'
  task :chargeback_report => [:environment, :setup_logger] do
    PayeezyAccountUpdater.process_chargebacks
  end
  
  desc 'Upload CAU request to First Data'
  task :account_updater_send_file_to_process => [:environment, :setup_logger] do
    PayeezyAccountUpdater.account_updater_send_file_to_process
  end
  
  desc 'Download and process CAU response'
  task :account_updater_process_response => [:environment, :setup_logger] do
    PayeezyAccountUpdater.account_updater_process_response
  end
end