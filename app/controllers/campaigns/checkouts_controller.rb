class Campaigns::CheckoutsController < ApplicationController
  skip_before_filter :verify_authenticity_token
  before_filter :authenticate_campaign_agent_from_token!
  skip_before_filter :authenticate_agent_from_token!
  skip_before_filter :authenticate_agent!
  skip_before_filter :validate_partner_presence
  before_filter :load_club_based_on_host, only: [:submit, :new, :create, :thank_you, :duplicated, :error, :critical_error]
  before_filter :load_campaign, only: [:submit, :new, :thank_you, :duplicated, :error]
  before_filter :set_page_title, only: [:new, :thank_you, :duplicated, :error, :critical_error]
  before_filter :campaign_active, only: [:submit, :new, :thank_you, :duplicated]
  before_filter :load_prospect, only: [:new, :duplicated, :error]
  before_filter :load_ga_tracking_id, only: [:new, :thank_you, :duplicated, :error, :critical_error]
  before_filter :setup_request_params, only: [:submit]

  layout 'checkout'

  def submit
    my_authorize! :checkout_submit, Campaign, @club.id
    if @club && @campaign && (@club.id == @campaign.club_id) # @campaign.landing_url.include? params[:landing_url]
      prospect = Checkout.new(campaign: @campaign).find_or_create_prospect_by params
      if prospect.nil?
        Rails.logger.error 'Checkout::SubmitError: Prospect not found.'
        redirect_to error_checkout_path, alert: I18n.t('error_messages.user_not_saved', cs_phone_number: @club.cs_phone_number)
      elsif prospect.error_messages && prospect.error_messages.any?
        redirect_to generate_edit_user_info_url(prospect)
      else
        redirect_to new_checkout_url(token: prospect.token, campaign_id: @campaign)
      end
    else
      Rails.logger.error 'Checkout::SubmitError: Campaign and Club inconsistencies '
      redirect_to error_checkout_path(campaign_id: @campaign), alert: I18n.t('error_messages.user_not_saved', cs_phone_number: @club.cs_phone_number)
    end
  rescue
    Rails.logger.error "Checkout::SubmitError: Error: #{$ERROR_INFO}"
    Auditory.report_issue('Checkout::SubmitError', $ERROR_INFO.to_s, campaign_slug: params[:landing_id])
    redirect_to error_checkout_path, alert: I18n.t('error_messages.user_not_saved', cs_phone_number: @club.cs_phone_number)
  end

  def new
    my_authorize! :checkout_new, Campaign, @prospect.club_id
    @product = Product.find_by(club_id: @prospect.club_id, sku: @prospect.product_sku)
    @edit_info_url = generate_edit_user_info_url(@prospect)
  rescue
    Rails.logger.error "Checkout::NewError: Error: #{$ERROR_INFO}"
    Auditory.report_issue('Checkout::NewError', $ERROR_INFO.to_s, campaign_slug: params[:campaign_id], prospect_token: params[:token])
    @club = @prospect ? @prospect.club : load_club_based_on_host
    redirect_to error_checkout_path, alert: I18n.t('error_messages.user_not_saved', cs_phone_number: @club.cs_phone_number)
  end

  def create
    @prospect = Prospect.where_token(params[:credit_card][:prospect_token])
    @campaign = Campaign.find_by!(slug: params[:credit_card][:campaign_id])
    prospect_attributes = @prospect.attributes.with_indifferent_access
    prospect_attributes[:campaign_id] = @prospect.campaign_code
    prospect_attributes[:prospect_id] = @prospect.id
    prospect_attributes[:preferences] = @prospect.preferences
    if @prospect && @campaign
      my_authorize! :checkout_create, Campaign, @prospect.club_id
      response = User.enroll(
        @campaign.terms_of_membership,
        nil, # current_agent .. which current agent should we use here?
        @campaign.enrollment_price,
        prospect_attributes,
        params[:credit_card]
      )
      if response[:code] == Settings.error_codes.success
        Rails.logger.info "Checkout::CreateSuccess: Response: #{response.inspect}"
        redirect_to thank_you_checkout_path(campaign_id: @campaign, user_id: User.find(response[:member_id]).to_param)
      else
        Rails.logger.error "Checkout::CreateError: #{response.inspect}"
        redirect_to (%w(407 409 9507).include?(response[:code]) ? duplicated_checkout_path(campaign_id: @campaign, token: @prospect.token) : error_checkout_path(campaign_id: @campaign, token: @prospect.token)), alert: response[:message]
      end
    end
  rescue
    Rails.logger.error "Checkout::CreateError: #{$ERROR_INFO}"
    Auditory.report_issue('Checkout::CreateError', $ERROR_INFO.to_s, campaign_slug: params[:credit_card][:campaign_id], prospect_token: params[:credit_card][:prospect_token])
    redirect_to error_checkout_path, alert: I18n.t('error_messages.user_not_saved', cs_phone_number: @club.cs_phone_number)
  end

  def thank_you
    @user = User.find_by!(slug: params[:user_id])
    sign_out current_agent if agent_signed_in?
  end

  def error; end

  def critical_error; end

  def duplicated
    sign_out current_agent if agent_signed_in?
  end

  private

  def setup_request_params
    params[:user_agent]  = request.user_agent.to_s
    params[:ip_address]  = request.remote_ip.to_s
    params[:landing_url] = request.referer.to_s.downcase
  end

  def load_club_based_on_host
    @club = Club.find_by(checkout_url: request.base_url)
  end

  def load_campaign
    @campaign = if params[:campaign_id].present?
                  Campaign.find_by! slug: params[:campaign_id]
                else
                  # TODO: We expect the ID of the Campaign coming as :landing_id.
                  # It will change in the future to :campaign_id.
                  Campaign.find_by slug: params[:landing_id]
                end
    raise ActiveRecord::RecordNotFound unless @campaign
  rescue ActiveRecord::RecordNotFound
    Rails.logger.error "Checkout::LoadCampaign: #{$ERROR_INFO} campaign_id: #{params[:campaign_id]}"
    redirect_to critical_error_checkout_path
  end

  def load_prospect
    @prospect = Prospect.where_token(params[:token])
    raise ActiveRecord::RecordNotFound unless @prospect
  rescue ActiveRecord::RecordNotFound
    Rails.logger.error "Checkout::LoadProspect: #{$ERROR_INFO} token: #{params[:token]}"
    redirect_to critical_error_checkout_path
  end

  def set_page_title
    @page_title = if @campaign.nil?
                    t('checkout.pages_titles.error')
                  else
                    "#{@campaign.name} - " + t('checkout.pages_titles.' + params[:action])
                  end
  end

  def load_ga_tracking_id
    ga_transport = @club.transport_settings.find_by(transport: 4)
    @ga_tracking_id = ga_transport.tracking_id unless ga_transport.nil?
  end

  def generate_edit_user_info_url(prospect = nil)
    prospect_token = ''
    if prospect
      prospect_token = (@campaign.landing_url.include?('?') ? '&' : '?') + { token: prospect.token }.to_param
    end
    @campaign.landing_url + prospect_token
  end

  def campaign_active
    return if @campaign.nil? || @campaign.active?
    Rails.logger.error 'Checkout::CheckIfActiveError: Campaign is not active'
    Auditory.report_issue('Checkout::CheckIfActiveError', '', campaign_id: @campaign.id, initial_date: @campaign.initial_date, finish_date: @campaign.finish_date, today: Date.today.to_s)
    redirect_to error_checkout_path, alert: I18n.t('error_messages.campaign_is_not_active')
  end

  def authenticate_campaign_agent_from_token!
    if params[:api_key].present?
      agent = Agent.find_for_authentication(authentication_token: params[:api_key])
      if agent && Devise.secure_compare(agent.authentication_token, params[:api_key])
        sign_in agent
      end
    end
    return if agent_signed_in?
    render file: "#{Rails.root}/public/401", status: 401, layout: false, formats: [:html]
  end
end
