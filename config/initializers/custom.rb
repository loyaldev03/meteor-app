require 'auditory'
require 'exception_notification'
SacPlatform::Application.config.middleware.use ExceptionNotifier
require 'lyris_service'
require 'clean_find_in_batches'
require 'axlsx'

ExactTargetSDK.config(:username => 'martin@xagax.com', 
  :password => 'carla&martin911', 
  :endpoint => 'https://webservice.s6.exacttarget.com/Service.asmx',
  :namespace => 'https://webservice.s6.exacttarget.com/etframework.wsdl')

ActiveMerchant::Billing::MerchantESolutionsGateway.wiredump_device = File.open("#{Rails.root}/log/active_merchant.log", "a+")  
ActiveMerchant::Billing::MerchantESolutionsGateway.wiredump_device.sync = true

LitleOnline::Configuration.logger = Logger.new("#{Rails.root}/log/active_merchant_litle.log")  
LitleOnline::Configuration.logger.level = Logger::DEBUG

ActiveMerchant::Billing::AuthorizeNetGateway.wiredump_device = File.open("#{Rails.root}/log/active_merchant_auth_net.log", "a+")  
ActiveMerchant::Billing::AuthorizeNetGateway.wiredump_device.sync = true


ActiveRecord::Batches.send(:include, CleanFindInBatches)

# config/initializers/delayed_job_config.rb
Delayed::Worker.destroy_failed_jobs = false
Delayed::Worker.sleep_delay = 60
Delayed::Worker.max_attempts = 3
Delayed::Worker.max_run_time = 5.minutes
Delayed::Worker.read_ahead = 10
Delayed::Worker.delay_jobs = !Rails.env.test?


class String
  def to_bool
    return true if self == true || self =~ (/(true|t|yes|y|1)$/i)
    return false if self == false || self.blank? || self =~ (/(false|f|no|n|0)$/i)
    Rails.logger.error "invalid value for Boolean: \"#{self}\""
    return false
  end
end