module SacMailchimp
  mattr_accessor :logger 

  def self.enable_integration!
    logger.info " ** Initializing SAC Mailchimp integration at #{I18n.l(Time.zone.now)}"

    require 'sac_mailchimp/models/member_extensions'
    require 'sac_mailchimp/models/member_model'
    require 'sac_mailchimp/models/prospect_extensions'
    require 'sac_mailchimp/models/prospect_model'
    require 'sac_mailchimp/controllers/members_controller_extensions'

    User.send :include, SacMailchimp::MemberExtensions
    Prospect.send :include, SacMailchimp::ProspectExtensions
    UsersController.send :include, SacMailchimp::MembersControllerExtensions
    
    logger.info "  * extending User and Prospect at #{I18n.l(Time.zone.now)}"

    nil
  end

  def self.config_integration(mailchimp_api_key)
    Gibbon::API.api_key = mailchimp_api_key
    Gibbon::API.throws_exceptions = true
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

  def self.report_error(message, error, subscriber)
    if not subscriber.club.billing_enable or error.to_s.include?("Timeout") or (error.instance_of? Gibbon::MailChimpError and not ["214"].include? error.code.to_s)
      logger.info error.inspect
    else
      Auditory.report_issue(message, error.inpsect, { error: error.inspect, :subscriber => subscriber.inspect, club: subscriber.club.inspect })
    end
  end

end