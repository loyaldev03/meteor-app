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
    Gibbon::Request.api_key = mailchimp_api_key
    Gibbon::Request.throws_exceptions = true
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

  def self.report_error(message, error, subscriber, notify_error = true)
    raise_exception = notify_error ? should_raise_exception?(error) : notify_error
    logger.info error.inspect
    if not subscriber.club.billing_enable
      subscriber.class.where(id: subscriber.id).update_all(need_sync_to_marketing_client: false)
    else
      raise error if raise_exception
    end
  end

  def self.should_raise_exception?(error)
    [
      I18n.t('mailchimp.error_details.cant_subscribe'),
      I18n.t('mailchimp.error_details.fake_or_invalid_email')
    ].select { |text| error.try(:detail).to_s.include?(text) }.empty?
  end
end