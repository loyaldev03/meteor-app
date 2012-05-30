require 'sac_drupal/drupal'

Drupal.logger = Rails.logger

# in test env, integration should be manually enabled in specific tests
#Drupal.enable_integration! unless Rails.env.test?

