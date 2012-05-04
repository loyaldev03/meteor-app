require 'auditory'
require 'clean_find_in_batches'

ActiveMerchant::Billing::MerchantESolutionsGateway.wiredump_device = File.open("#{Rails.root}/log/active_merchant.log", "a+")  
ActiveMerchant::Billing::MerchantESolutionsGateway.wiredump_device.sync = true

ActiveRecord::Batches.send(:include, CleanFindInBatches)
