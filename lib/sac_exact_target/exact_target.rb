module SacExactTarget
  mattr_accessor :logger

  def self.enable_integration!
    logger.info " ** Initializing SAC Exact Target integration"

    require 'sac_exact_target/models/club_extensions'
    require 'sac_exact_target/models/member_extensions'
    require 'sac_exact_target/models/prospect_extensions'
    require 'sac_exact_target/models/member_model'
    require 'sac_exact_target/models/prospect_model'
    require 'sac_exact_target/controllers/members_controller_extensions'


    Club.send :include, SacExactTarget::ClubExtensions
    Member.send :include, SacExactTarget::MemberExtensions
    Prospect.send :include, SacExactTarget::ProspectExtensions
    MembersController.send :include, SacExactTarget::MembersControllerExtensions

    logger.info "  * extending Member and Club"

    nil
  end

  def self.config_integration(username, password)
    ExactTargetSDK.config(:username => username, :password => password,
      :endpoint => 'https://webservice.s6.exacttarget.com/Service.asmx',
      :namespace => 'http://exacttarget.com/wsdl/partnerAPI',
      :open_timeout => 60)
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

  def self.report_error(error_message, result)
    if [ 12002, 12004, 12000 ].include?(result.Results.first.error_code.to_i)
      logger.info result.inspect
    else
      Auditory.report_issue(error_message, result.Results.first.status_message, { :result => result.inspect })
    end
  end

end
