module Mailchimp
  mattr_accessor :logger

  def self.enable_integration!
    logger.info " ** Initializing SAC Mailchimp integration"

    # require 'sac_exact_target/models/club_extensions'
    # require 'sac_exact_target/models/member_extensions'
    # require 'sac_exact_target/models/prospect_extensions'
    # require 'sac_exact_target/models/member_model'
    # require 'sac_exact_target/models/prospect_model'
    # require 'sac_exact_target/controllers/members_controller_extensions'


    # Club.send :include, SacExactTarget::ClubExtensions
    # Member.send :include, SacExactTarget::MemberExtensions
    # Prospect.send :include, SacExactTarget::ProspectExtensions
    # MembersController.send :include, SacExactTarget::MembersControllerExtensions

    logger.info "  * extending Member and Club"

    nil
  end

end