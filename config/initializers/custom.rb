require 'auditory'
require 'clean_find_in_batches'

ActiveMerchant::Billing::MerchantESolutionsGateway.wiredump_device = File.open("#{Rails.root}/log/active_merchant.log", "a+")  
ActiveMerchant::Billing::MerchantESolutionsGateway.wiredump_device.sync = true

ActiveRecord::Batches.send(:include, CleanFindInBatches)

# config/initializers/delayed_job_config.rb
Delayed::Worker.destroy_failed_jobs = false
Delayed::Worker.sleep_delay = 60
Delayed::Worker.max_attempts = 3
Delayed::Worker.max_run_time = 5.minutes
Delayed::Worker.read_ahead = 10
Delayed::Worker.delay_jobs = !Rails.env.test?
