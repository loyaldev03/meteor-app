require "active_merchant/billing/rails"
require 'lyris_service'
# # We are commenting log writing due to https://www.pivotaltracker.com/story/show/68819072 since how logs are written is not pci compliant (Only for production).
if Rails.env.staging? or Rails.env.prototype?
    ActiveMerchant::Billing::MerchantESolutionsGateway.wiredump_device = File.open("#{Rails.root}/log/active_merchant.log", "a+")
    ActiveMerchant::Billing::MerchantESolutionsGateway.wiredump_device.sync = true

    LitleOnline::Configuration.logger = Logger.new("#{Rails.root}/log/active_merchant_litle.log")  
    LitleOnline::Configuration.logger.level = Logger::DEBUG

    ActiveMerchant::Billing::AuthorizeNetGateway.wiredump_device = File.open("#{Rails.root}/log/active_merchant_auth_net.log", "a+")  
    ActiveMerchant::Billing::AuthorizeNetGateway.wiredump_device.sync = true

  ActiveMerchant::Billing::TrustCommerceGateway.wiredump_device = File.open("#{Rails.root}/log/active_merchant_trust_commerce.log", "a+")  
  ActiveMerchant::Billing::TrustCommerceGateway.wiredump_device.sync = true
end
