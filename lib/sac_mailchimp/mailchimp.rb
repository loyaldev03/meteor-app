module SacMailchimp
  mattr_accessor :logger

  def self.enable_integration!
    logger.info " ** Initializing SAC Mailchimp integration"

    require 'sac_mailchimp/models/member_extensions'
    require 'sac_mailchimp/models/member_model'
    require 'sac_mailchimp/models/prospect_extensions'
    require 'sac_mailchimp/models/prospect_model'
    require 'sac_mailchimp/controllers/members_controller_extensions'

    Member.send :include, SacMailchimp::MemberExtensions
    Prospect.send :include, SacMailchimp::ProspectExtensions
    MembersController.send :include, SacMailchimp::MembersControllerExtensions
    
    logger.info "  * extending Member and Prospect"

    nil
  end

  def self.config_integration(mailchimp_api_key)
    Gibbon::API.api_key = mailchimp_api_key
    Gibbon::API.throws_exceptions = false
  end

  def self.format_attribute(object, api_field, our_field)
    value = object.send(our_field)
    if value.class == ActiveSupport::TimeWithZone
      {api_field => I18n.l(value)} 
    elsif value.class == Date
      {api_field => I18n.l(value)}
    else
      {api_field => value.to_s}
    end
  end

end