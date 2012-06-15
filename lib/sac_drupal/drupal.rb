module Drupal
  mattr_accessor :logger

  def self.enable_integration!
    logger.info " ** Initializing SAC Drupal integration"

    require 'sac_drupal/models/member'
    require 'sac_drupal/models/club_extensions'
    require 'sac_drupal/faraday_middleware/full_logger'
    require 'sac_drupal/faraday_middleware/drupal_authentication'

    logger.info "  * extending Member and Club"
    Club.send :include, Drupal::ClubExtensions

    if Faraday.respond_to? :register_middleware
      logger.info "  * registering Faraday middleware: DrupalAuthentication"
      Faraday.register_middleware :request,
        :drupal_auth    => lambda { ::Drupal::FaradayMiddleware::DrupalAuthentication }
    end

    nil
  end

  def self.test_mode!
    Club.send :include, Drupal::ClubTestExtensions
  end
end
