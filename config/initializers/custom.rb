require 'auditory'
require 'exception_notification'
require 'axlsx'
require 'csv'
Dir["#{Rails.root}/lib/exceptions/*.rb"].each {|file| require file }
Dir["#{Rails.root}/lib/extensions/*.rb"].each {|file| require file }

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

class String
  def to_bool
    return true if self == true || self =~ (/(true|t|yes|y|1)$/i)
    return false if self == false || self.blank? || self =~ (/(false|f|no|n|0)$/i)
    Rails.logger.error "invalid value for Boolean: \"#{self}\""
    return false
  end
end

# require 'bureaucrat'
# require 'bureaucrat/quickfields'
# require 'bureaucrat/form'
