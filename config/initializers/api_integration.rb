require 'sac_drupal/drupal'
Drupal.logger = Rails.logger
# in test env, integration should be manually enabled in specific tests
Drupal.enable_integration! unless Rails.env.test?

# require 'sac_wordpress/wordpress'
# Wordpress.logger = Rails.logger
# Wordpress.enable_integration! unless Rails.env.test?

require 'sac_pardot/pardot'
Pardot.logger = Rails.logger
# in test env, integration should be manually enabled in specific tests
Pardot.enable_integration! unless Rails.env.test?
