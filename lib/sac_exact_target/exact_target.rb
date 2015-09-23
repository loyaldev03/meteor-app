module SacExactTarget
  mattr_accessor :logger

  def self.enable_integration!
    logger.info " ** Initializing SAC Exact Target integration at #{I18n.l(Time.zone.now)}"

    require 'sac_exact_target/models/club_extensions'
    require 'sac_exact_target/models/member_extensions'
    require 'sac_exact_target/models/prospect_extensions'
    require 'sac_exact_target/models/member_model'
    require 'sac_exact_target/models/prospect_model'
    require 'sac_exact_target/controllers/members_controller_extensions'


    Club.send :include, SacExactTarget::ClubExtensions
    User.send :include, SacExactTarget::MemberExtensions
    Prospect.send :include, SacExactTarget::ProspectExtensions
    UsersController.send :include, SacExactTarget::MembersControllerExtensions

    logger.info "  * extending User and Club at #{I18n.l(Time.zone.now)}"

    nil
  end

  def self.config_integration(username, password, endpoint)
    ExactTargetSDK.config(:username => username, :password => password, :endpoint => endpoint,
      :namespace => 'http://exacttarget.com/wsdl/partnerAPI', :open_timeout => 60)
  end

  def self.format_attribute(object, api_field, our_field)
    value = object.send(our_field)
    if value.class == ActiveSupport::TimeWithZone
      ExactTargetSDK::Attributes.new(Name: api_field, Value: I18n.l(value)) 
    elsif value.class == Date
      ExactTargetSDK::Attributes.new(Name: api_field, Value: I18n.l(value)) 
    else
      ExactTargetSDK::Attributes.new(Name: api_field, Value: value.to_s) 
    end
  end 

  def self.report_error(message, error, subscriber)
    if not subscriber.club.billing_enable or error.to_s.include?("Timeout") or [ 12002, 12004, 12000 ].include?(error.Results.first.error_code.to_i)
      logger.info error.inspect
    else
      Auditory.report_issue(message, error.Results.first.status_message, { error: error.inspect, :subscriber => subscriber.inspect, club: subscriber.club.inspect })
    end
  end

end
