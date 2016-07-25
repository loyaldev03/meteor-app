class TransportSettingsController < ApplicationController
  before_action :set_transport_setting, only: [:show, :edit, :update, :destroy]

  def index
    # my_authorize! :list, TransportSetting, @current_club.id
    respond_to do |format|
      format.html
      format.json { render json: TransportSetting.new(view_context, @current_partner, @current_club, @current_user, @current_agent)}
    end 
  end

  def show
  end

  def new
    @transport_setting = TransportSetting.new
  end

  def edit
  end

  def create
    @transport_setting = TransportSetting.new(transport_setting_params)

    if @transport_setting.save
      redirect_to @transport_setting, notice: 'Transport setting was successfully created.'
    else
      render :new
    end
  end

  def update
    if @transport_setting.update(transport_setting_params)
      redirect_to @transport_setting, notice: 'Transport setting was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @transport_setting.destroy
    redirect_to transport_settings_url, notice: 'Transport setting was successfully destroyed.'
  end

  private
    def set_transport_setting
      @transport_setting = TransportSetting.find(params[:id])
    end

    def transport_setting_params
      params[:transport_setting]
    end
end
