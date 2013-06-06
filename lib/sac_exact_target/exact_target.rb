module SacExactTarget
  mattr_accessor :logger

  def self.enable_integration!
    logger.info " ** Initializing SAC Exact Target integration"

    require 'sac_exact_target/models/member'
    require 'sac_exact_target/models/prospect'
    require 'sac_exact_target/models/club_extensions'

    logger.info "  * extending Prospect, Member and Club"
    Club.send :include, SacExactTarget::ClubExtensions

    nil
  end
end
