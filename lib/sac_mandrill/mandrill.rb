module SacMandrill
  mattr_accessor :logger

  def self.enable_integration!
    logger.info " ** Initializing SAC Mailchimp integration"

    require 'mandrill'
    require 'sac_mandrill/models/member_extensions'
    require 'sac_mandrill/models/member_model'

    Member.send :include, SacMandrill::MemberExtensions
    
    logger.info "  * extending Member and Prospect"

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