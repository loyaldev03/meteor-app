module Spree
  mattr_accessor :logger

  def self.enable_integration!
    logger.info " ** Initializing SAC Spree integration at #{I18n.l(Time.zone.now)}"

    require 'sac_spree/models/member'
    require 'sac_spree/models/club_extensions'

    logger.info "  * extending Member and Club at #{I18n.l(Time.zone.now)}"
    Club.send :include, Spree::ClubExtensions

    nil
  end

  def self.test_mode!
    # Club.send :include, Drupal::ClubTestExtensions
  end
end
