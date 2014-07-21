require 'sac_drupal/drupal'
Drupal.logger = Rails.logger
# in test env, integration should be manually enabled in specific tests
Drupal.enable_integration! unless Rails.env.test? or Rails.env.development?

# require 'sac_wordpress/wordpress'
# Wordpress.logger = Rails.logger
# Wordpress.enable_integration! unless Rails.env.test?

#require 'sac_pardot/pardot'
#Pardot.logger = Rails.logger
# in test env, integration should be manually enabled in specific tests
#Pardot.enable_integration! unless Rails.env.test?

require 'sac_exact_target/exact_target'
require 'sac_mailchimp_mandrill/mailchimp'

SacExactTarget.logger = Rails.logger
SacMailchimp.logger = Rails.logger
# in test env, integration should be manually enabled in specific tests
SacExactTarget.enable_integration! unless Rails.env.test? or Rails.env.development?
SacMailchimp.enable_integration!