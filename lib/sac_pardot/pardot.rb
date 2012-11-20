module Pardot
  mattr_accessor :logger

  def self.enable_integration!
    logger.info " ** Initializing SAC Pardot integration"

    require 'sac_pardot/models/member'
    require 'sac_pardot/models/prospect'
    require 'sac_pardot/models/club_extensions'

    logger.info "  * extending Prospect, Member and Club"
    Club.send :include, Pardot::ClubExtensions

    nil
  end
end
