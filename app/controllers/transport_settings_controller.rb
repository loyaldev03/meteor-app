class TransportSettingsController < ApplicationController
  before_filter :validate_club_presence
  before_action :set_transport, only: [:show, :edit, :update, :test_connection]

  def index
    my_authorize! :list, TransportSetting, current_club.id
    respond_to do |format|
      format.html
      format.json { render json: TransportSettingsDatatable.new(view_context, current_partner, current_club, current_user, current_agent)}
    end 
  end

  def show
    my_authorize! :read, TransportSetting, @transport.club_id
  end

  def new
    my_authorize! :new, TransportSetting, current_club.id
    if current_club.available_transport_settings.first.present?
      @transport = TransportSetting.new
    else
      redirect_to transport_settings_url, alert: 'No more Transports available.'
    end
  end

  def edit
    my_authorize! :edit, TransportSetting, @transport.club_id
  end

  def create
    my_authorize! :create, TransportSetting, current_club.id
    @transport = TransportSetting.new(transport_params)
    @transport.club_id = current_club.id
    if @transport.save
      redirect_to transport_setting_path(partner_prefix: current_partner.prefix, club_prefix: current_club.name, id: @transport), 
        notice: "The transport setting for <b>#{@transport.transport_i18n}</b> was successfully created.".html_safe
    else
      flash.now[:error] = 'Couldn\'t create transport setting.'
      render :new
    end
  end

  def update
    my_authorize! :update, TransportSetting, @transport.club_id
    if @transport.update(transport_params_on_update)
      redirect_to transport_setting_path(partner_prefix: current_partner.prefix, club_prefix: current_club.name, id: @transport), 
        notice: "The transport setting for <b>#{@transport.transport_i18n}</b> was successfully updated.".html_safe
    else
      flash.now[:error] = 'Couldn\'t update transport setting.'
      render :edit
    end
  end

  def test_connection
    my_authorize! :test_connection, TransportSetting, @transport.club_id
    response = @transport.test_connection!
    if response[:success]
      flash[:notice] = "Phoenix can connect to the remote API correctly."
    else
      flash[:error] = "There was an error while connecting to the remote API. " + response[:message]
    end
  rescue TransportDoesntSupportAction => e
    flash[:error] = "Transport does not support this action."
  ensure
    redirect_to transport_settings_path(partner_prefix: current_partner.prefix, club_prefix: current_club.name)
  end

  private
    def set_transport
      @transport = TransportSetting.find(params[:id])
    end

    def transport_params
      params.require(:transport_setting).permit(:transport, :client_id, :client_secret, :access_token, :api_key, :tracking_id, :container_id, :url, :api_token)
    end

    def transport_params_on_update
      params.require(:transport_setting).permit(:client_id, :client_secret, :access_token, :api_key, :tracking_id, :container_id, :url, :api_token)
    end
end
