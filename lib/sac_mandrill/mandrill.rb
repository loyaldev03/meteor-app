module SacMandrill
  mattr_accessor :logger

  def self.enable_integration!
    logger.info " ** Initializing SAC Mailchimp integration at #{I18n.l(Time.zone.now)}"

    require 'mandrill'
    require 'sac_mandrill/models/member_extensions'
    require 'sac_mandrill/models/member_model'

    User.send :include, SacMandrill::MemberExtensions
    
    logger.info "  * extending User and Prospect at #{I18n.l(Time.zone.now)}"

    nil
  end

  def self.format_attribute(object, api_field, our_field)
    value = object.send(our_field)
    if value.class == ActiveSupport::TimeWithZone
      {"name" => api_field, "content" => I18n.l(value)}
    elsif value.class == Date
      {"name" => api_field, "content" => I18n.l(value)}
    else
      {"name" => api_field, "content" => value.to_s}
    end
  end

end