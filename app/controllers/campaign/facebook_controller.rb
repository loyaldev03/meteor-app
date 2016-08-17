class Campaign::FacebookController < ApplicationController
  before_filter :validate_club_presence
  before_action :set_transport_settings

  def request_code
    if @transport_setting
      redirect_to client.authorization_uri(:scope => [:ads_read])
    else
      redirect_to new_club_transport_setting(current_club)
    end
  # rescue AttrRequired::AttrMissing
    # flash[:error] = I18n.t('activerecord.errors.models.transport_setting.attributes.settings.missing_required', keys: '')
    # redirect_to edit_club_transport_setting_path(club_id: @club_id, id: @transport_setting.id)
  end

  def generate_token
    client.authorization_code = params[:code]
    access_token = client.access_token!
    @transport_setting.settings["access_token"] = access_token.to_s
    @transport_setting.save
    Campaigns::UnauthorizedDaysDataFetcherJob.perform_later(@transport_setting.id)

    flash[:notice] = 'Facebook access token retrieved successfully.'
  rescue Rack::OAuth2::Client::Error
    flash[:error] = 'Unable to retrieve Facebook access token. Make sure the client id and client secret are the correct ones.'
  ensure
    redirect_to transport_setting_path(partner_prefix: current_partner.prefix, club_id: current_club.id, id: @transport_setting.id)
  end

  private 

    def authorize_manager!
      authorize Club.find(params[:club_id])
    end

    def set_transport_settings
      @transport_setting = current_club.transport_settings.facebook.first
    end

    def client
      @client ||= FbGraph2::Auth.new(
        @transport_setting.settings['client_id'].to_i, 
        @transport_setting.settings['client_secret'], 
        redirect_uri: campaign_facebook_access_token_campaigns_url(partner_prefix: current_club.partner.prefix, club_prefix: current_club.name)
      )
    end

end