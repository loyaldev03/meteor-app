module Pardot
  mattr_accessor :logger

  def self.enable_integration!
    logger.info " ** Initializing SAC Pardot integration at #{I18n.l(Time.zone.now, :format =>:dashed)}"

    require 'sac_pardot/models/member_extensions'
    User.send :include, Pardot::MemberExtensions
 
    require 'sac_pardot/models/prospect_extensions'
    Prospect.send :include, Pardot::ProspectExtensions

    require 'sac_pardot/models/member'
    require 'sac_pardot/models/prospect'
    require 'sac_pardot/models/club_extensions'
    require 'sac_pardot/controllers/members_controller_extensions'

    logger.info "  * extending Prospect, Member and Club at #{I18n.l(Time.zone.now, :format =>:dashed)}"
    Club.send :include, Pardot::ClubExtensions
    UsersController.send :include, Pardot::MembersControllerExtensions

    nil
  end
end
