class Campaigns::CheckoutsController < ApplicationController
  skip_before_filter :verify_authenticity_token
  before_filter :authenticate_campaign_agent_from_token!, except: %i[thank_you duplicated error critical_error]
  skip_before_filter :authenticate_agent_from_token!
  skip_before_filter :authenticate_agent!
  skip_before_filter :validate_partner_presence
  before_filter :load_club_based_on_host, only: %i[submit new create thank_you duplicated error critical_error]
  before_filter :load_campaign, only: %i[submit new thank_you duplicated error]
  before_filter :set_page_title, only: %i[new thank_you duplicated error critical_error]
  before_filter :set_appletouch_icon, only: %i[new thank_you duplicated error critical_error]
  before_filter :campaign_active, only: %i[submit new thank_you duplicated]
  before_filter :load_prospect, only: %i[new duplicated error create]
  before_filter :load_user, only: :thank_you
  before_filter :load_ga_tracking_id, only: %i[new thank_you duplicated error critical_error]
  before_filter :setup_request_params, only: [:submit]
  before_filter :can_show_page?, only: %i[thank_you duplicated error]
  before_filter :store_current_page, only: %i[new thank_you duplicated error critical_error]
  before_filter :checkout_settings, only: %i[new thank_you duplicated error critical_error]

  layout 'checkout'

  def submit
    my_authorize! :checkout_submit, Campaign, @club.id
    if @club && @campaign && (@club.id == @campaign.club_id) # @campaign.landing_url.include? params[:landing_url]
      prospect = Checkout.new(campaign: @campaign).find_or_create_prospect_by params
      if prospect.nil?
        Rails.logger.error 'Checkout::SubmitError: Prospect not found.'
        redirect_to error_checkout_path(campaign_id: @campaign), alert: I18n.t('error_messages.user_not_saved', cs_phone_number: @club.cs_phone_number)
      elsif prospect.error_messages && prospect.error_messages.any?
        redirect_to generate_edit_user_info_url(prospect)
      elsif @campaign.credit_card_and_geographic_required?
        redirect_to new_checkout_url(token: prospect.token, campaign_id: @campaign)
      else
        create_user(prospect, @campaign, true)
      end
    else
      Rails.logger.error 'Checkout::SubmitError: Campaign and Club inconsistencies '
      redirect_to error_checkout_path(campaign_id: @campaign), alert: I18n.t('error_messages.user_not_saved', cs_phone_number: @club.cs_phone_number)
    end
  rescue StandardError
    Rails.logger.error "Checkout::SubmitError: Error: #{$ERROR_INFO}"
    Auditory.report_issue('Checkout::SubmitError', $ERROR_INFO)
    redirect_to error_checkout_path(campaign_id: @campaign), alert: I18n.t('error_messages.user_not_saved', cs_phone_number: @club.cs_phone_number)
  end

  def new
    my_authorize! :checkout_new, Campaign, @club
    @product = Product.find_by(club_id: @prospect.club_id, sku: @prospect.product_sku)
    @edit_info_url = generate_edit_user_info_url(@prospect)
    @show_bbb_seal = Settings['club_params'][@club.id]['show_bbb_seal']
  rescue StandardError
    Rails.logger.error "Checkout::NewError: Error: #{$ERROR_INFO}"
    Auditory.report_issue('Checkout::NewError', $ERROR_INFO)
    @club = @prospect ? @prospect.club : load_club_based_on_host
    redirect_to error_checkout_path(campaign_id: @campaign, token: @prospect.token), alert: I18n.t('error_messages.user_not_saved', cs_phone_number: @club.cs_phone_number)
  end

  def create
    @campaign = Campaign.find_by!(slug: params[:credit_card][:campaign_id])
    if @prospect && @campaign
      my_authorize! :checkout_create, Campaign, @prospect.club_id
      create_user(@prospect, @campaign)
    end
  rescue StandardError
    Rails.logger.error "Checkout::CreateError: #{$ERROR_INFO}"
    Auditory.report_issue('Checkout::CreateError', $ERROR_INFO)
    redirect_to error_checkout_path(campaign_id: @campaign, token: @prospect.token), alert: I18n.t('error_messages.user_not_saved', cs_phone_number: @club.cs_phone_number)
  end

  def thank_you; end

  def duplicated; end

  def error
    @error_message = if %w[904 905].include?(params[:response_code])
                       landing_page_url = generate_edit_user_info_url(@prospect)
                       "<h2>We're Sorry!</h2><p>Due to the popularity of your selected item, we just ran out! If you would like to select a different item, <a href=" + landing_page_url + '>please click here!</a></p><p>If you have any questions, please contact our Member Service team at %%CS_PHONE_NUMBER%% (Monday - Friday 9am-5pm EST) or email at <a href="mailto:%%CS_EMAIL%%">%%CS_EMAIL%%</a>.</p>'
                     else
                       @checkout_settings[:error_page_content]
                     end
  end

  def critical_error; end

  private

  def setup_request_params
    params[:user_agent]  = request.user_agent.to_s
    params[:ip_address]  = request.remote_ip.to_s
    params[:landing_url] = request.referer.to_s.downcase
  end

  def load_club_based_on_host
    @club = Club.find_by!(checkout_url: request.base_url)
  rescue ActiveRecord::RecordNotFound
    Rails.logger.error "Checkout::LoadClubBasedOnHost: Couldn't find Club for host: #{request.base_url}"
    Auditory.report_issue("Checkout::LoadClubBasedOnHost: Couldn't find Club for host: #{request.base_url}", $ERROR_INFO, base_url: request.base_url)
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
    token = params[:credit_card] ? params[:credit_card][:prospect_token] : params[:token]
    @prospect = Prospect.where_token(token) if token.present?
    raise ActiveRecord::RecordNotFound unless @prospect
  rescue ActiveRecord::RecordNotFound
    Rails.logger.error "Checkout::LoadProspect: #{$ERROR_INFO} token: #{params[:token]}"
    redirect_to critical_error_checkout_path
  end

  def load_user
    @user = User.find_by!(slug: params[:user_id])
  rescue ActiveRecord::RecordNotFound
    Rails.logger.error "Checkout::LoadUser: #{$ERROR_INFO} slug: #{params[:user_id]}"
    redirect_to critical_error_checkout_path
  end

  def set_page_title
    @page_title = if @campaign.nil?
                    t('checkout.pages_titles.error')
                  else
                    "#{@campaign.title} - " + t('checkout.pages_titles.' + params[:action])
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
    Auditory.notify_pivotal_tracker('Checkout: User tried enrolling to a closed campaign', 'There was an enrollment try to an already closed campaign. Please make sure that the campaign is properly closed in the Source.', campaign_id: @campaign.id, initial_date: @campaign.initial_date, finish_date: @campaign.finish_date, today: Date.today.to_s)
    redirect_to error_checkout_path(campaign_id: @campaign), alert: I18n.t('error_messages.campaign_is_not_active')
  end

  def authenticate_campaign_agent_from_token!
    if params[:api_key].present?
      agent = Agent.find_for_authentication(authentication_token: params[:api_key])
      sign_in agent if agent && Devise.secure_compare(agent.authentication_token, params[:api_key])
    end
    return if agent_signed_in?

    load_campaign
    if @campaign && @campaign.landing_url.present?
      redirect_to @campaign.landing_url
    else
      redirect_to critical_error_checkout_path
    end
  rescue StandardError
    Rails.logger.error "Checkout::AuthenticateCampaignAgentFromToken: #{$ERROR_INFO}"
    Auditory.report_issue('Checkout::AuthenticateCampaignAgentFromToken', $ERROR_INFO)
    redirect_to critical_error_checkout_path
  end

  def create_user(prospect, campaign, cc_blank = false)
    prospect_attributes = prospect.attributes.with_indifferent_access
    prospect_attributes[:campaign_id] = prospect.campaign_code
    prospect_attributes[:prospect_id] = prospect.id
    prospect_attributes[:preferences] = prospect.preferences
    response = User.enroll(
      campaign.terms_of_membership,
      current_agent,
      campaign.enrollment_price,
      prospect_attributes,
      params[:credit_card],
      cc_blank,
      @campaign.create_remote_user_in_background
    )
    if response[:code] == Settings.error_codes.success
      Rails.logger.info "Checkout::CreateSuccess: Response: #{response.inspect}"
      redirect_to thank_you_checkout_path(campaign_id: @campaign, user_id: User.find(response[:member_id]).slug)
    else
      Rails.logger.error "Checkout::CreateError: #{response.inspect}"
      if %w[407 409 9507].include?(response[:code])
        redirect_to duplicated_checkout_path(campaign_id: @campaign, token: prospect.token)
      else
        redirect_to error_checkout_path(campaign_id: @campaign, token: prospect.token, response_code: response[:code])
      end
    end
  end

  def store_current_page
    session[:last_visited_page] = params[:action].to_s
  end

  def can_show_page?
    return if agent_signed_in? || session[:last_visited_page]

    load_campaign
    if @campaign && @campaign.landing_url.present?
      redirect_to @campaign.landing_url
    else
      redirect_to critical_error_checkout_path
    end
  end

  def checkout_settings
    @checkout_settings ||= if @campaign
                             @campaign.checkout_settings
                           else
                             @club.as_json(
                               only:
                              %i[checkout_page_bonus_gift_box_content
                                 checkout_page_footer
                                 css_style
                                 duplicated_page_content
                                 error_page_content
                                 result_page_footer
                                 thank_you_page_content],
                               methods:
                               %i[favicon
                                  result_pages_image
                                  header_image]
                             ).with_indifferent_access
                           end
  end

  def set_appletouch_icon
    @appletouch_icon = if @club.appletouch_icon_file_name.present?
                         @club.appletouch_icon.url
                       else
                         '/apple-touch-icon-precomposed.png'
                       end
  end
end
