class TransportSettingsController < ApplicationController
  before_filter :validate_club_presence
  before_action :set_transport, only: [:show, :edit, :update]

  def index
    my_authorize! :list, TransportSetting, current_club.id
    respond_to do |format|
      format.html
      format.json { render json: TransportSettingsDatatable.new(view_context, current_partner, current_club, current_user, current_agent)}
    end 
  end

  def show
    my_authorize! :read, TransportSetting, current_club.id
  end

  def new
    my_authorize! :new, TransportSetting, current_club.id
    if current_club.available_transport_settings.count > 0
      @transport = TransportSetting.new
    else
      flash[:error] = "No more Transports available."
      redirect_to transport_settings_url
    end
  end

  def edit
    my_authorize! :edit, TransportSetting, current_club.id
  end

  def create
    my_authorize! :create, TransportSetting, current_club.id
    @transport = TransportSetting.new(transport_params)
    @transport.club_id = current_club.id
    if @transport.save
      redirect_to transport_setting_path(partner_prefix: current_partner.prefix, club_prefix: current_club.name, id: @transport), 
        notice: "The transport setting for <b>#{@transport.transport}</b> was successfully created.".html_safe
    else
      render :new
    end
  end

  def update
    my_authorize! :update, TransportSetting, current_club.id
    if @transport.update(transport_params_on_update)
      redirect_to transport_setting_path(partner_prefix: current_partner.prefix, club_prefix: current_club.name, id: @transport), 
        notice: "The transport setting for <b>#{@transport.transport}</b> was successfully updated.".html_safe
    else
      render :edit
    end
  end

  private
    def set_transport
      @transport = TransportSetting.find(params[:id])
    end

    def transport_params
      params.require(:transport_setting).permit(:transport, :fb_client_id, :fb_client_secret, :fb_access_token, :mc_api_key)
    end

    def transport_params_on_update
      params.require(:transport_setting).permit(:fb_client_id, :fb_client_secret, :fb_access_token, :mc_api_key)
    end
end
