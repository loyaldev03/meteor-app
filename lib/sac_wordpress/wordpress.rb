module Wordpress
  mattr_accessor :logger

  def self.enable_integration!
    logger.info " ** Initializing SAC Wordpress integration at #{I18n.l(Time.zone.now, :format =>:dashed)}"

    require 'sac_wordpress/models/member'
    require 'sac_wordpress/models/club_extensions'
    require 'sac_wordpress/faraday_middleware/full_logger'

    logger.info "  * extending User and Club at #{I18n.l(Time.zone.now, :format =>:dashed)}"
    Club.send :include, Wordpress::ClubExtensions

    nil
  end

  def self.test_mode!
  end
end
