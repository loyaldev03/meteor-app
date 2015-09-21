module Drupal
  mattr_accessor :logger

  def self.enable_integration!
    logger.info " ** Initializing SAC Drupal integration at #{I18n.l(Time.zone.now)}"

    require 'sac_drupal/models/member'
    require 'sac_drupal/models/user_points'
    require 'sac_drupal/models/club_extensions'
    require 'sac_drupal/faraday_middleware/full_logger'
    require 'sac_drupal/faraday_middleware/drupal_authentication'
    require 'sac_drupal/faraday_middleware/fix_non_json_body'

    logger.info "  * extending Member and Club at #{I18n.l(Time.zone.now)}"
    Club.send :include, Drupal::ClubExtensions

    if Faraday.respond_to? :register_middleware
      logger.info "  * registering Faraday middleware: DrupalAuthentication"
      Faraday.register_middleware :request,
        :drupal_auth       => lambda { ::Drupal::FaradayMiddleware::DrupalAuthentication }
      logger.info "  * registering Faraday middleware: FixNonJsonBody"
      Faraday.register_middleware :response,
        :fix_non_json_body => lambda { ::Drupal::FaradayMiddleware::FixNonJsonBody }
    end

    nil
  end

  def self.test_mode!
    Club.send :include, Drupal::ClubTestExtensions
  end
end
