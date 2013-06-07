module SacExactTarget
  mattr_accessor :logger

  def self.enable_integration!
    logger.info " ** Initializing SAC Exact Target integration"

    require 'sac_exact_target/models/member_extensions'
    Member.send :include, SacExactTarget::MemberExtensions

    require 'sac_exact_target/models/member'
    require 'sac_exact_target/models/prospect'
    require 'sac_exact_target/models/club_extensions'
    require 'sac_exact_target/controllers/members_controller_extensions'
    
    Club.send :include, SacExactTarget::ClubExtensions
    MembersController.send :include, SacExactTarget::MembersControllerExtensions

    logger.info "  * extending Member and Club"

    nil
  end
end
