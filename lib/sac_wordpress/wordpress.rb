module Drupal
  mattr_accessor :logger

  def self.enable_integration!
    logger.info " ** Initializing SAC Wordpress integration"

    require 'sac_wordpress/models/member'
    require 'sac_wordpress/models/club_extensions'
    require 'sac_wordpress/faraday_middleware/full_logger'
    require 'sac_wordpress/observers/sync'

    logger.info "  * extending Member and Club"
    ::Member.send :include, Wordpress::MemberExtensions
    Club.send :include, Wordpress::ClubExtensions

    logger.info "  * registering sync Member observer"
    ::Member.add_observer Wordpress::Sync.instance

    if Faraday.respond_to? :register_middleware
      logger.info "  * registering Faraday middleware: WordpressAuthentication"
      Faraday.register_middleware :request,
        :wordpress_auth    => lambda { ::Wordpress::FaradayMiddleware::WordpressAuthentication }
    end

    nil
  end

  def self.test_mode!
  end
end
