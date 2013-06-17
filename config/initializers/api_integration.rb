require 'sac_drupal/drupal'
Drupal.logger = Rails.logger
# in test env, integration should be manually enabled in specific tests
Drupal.enable_integration! unless Rails.env.test?

# require 'sac_wordpress/wordpress'
# Wordpress.logger = Rails.logger
# Wordpress.enable_integration! unless Rails.env.test?

#require 'sac_pardot/pardot'
#Pardot.logger = Rails.logger
# in test env, integration should be manually enabled in specific tests
#Pardot.enable_integration! unless Rails.env.test?

require 'sac_exact_target/exact_target'
SacExactTarget.logger = Rails.logger
# in test env, integration should be manually enabled in specific tests
SacExactTarget.enable_integration! unless Rails.env.test?

ExactTargetSDK.config(:username => Settings.exact_target.username, 
             :password => Settings.exact_target.password, 
             :endpoint => 'https://webservice.s6.exacttarget.com/Service.asmx',
             :namespace => 'http://exacttarget.com/wsdl/partnerAPI',
             :open_timeout => 60)
