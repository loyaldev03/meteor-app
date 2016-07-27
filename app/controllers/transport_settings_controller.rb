class TransportSettingsController < ApplicationController
  before_action :set_transport, only: [:show, :edit, :update]

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
    @transport = TransportSetting.new
  end

  def edit
  end

  def create
    @transport = TransportSetting.new(transport_params)

    if @transport.save
      redirect_to @transport, notice: 'Transport was successfully created.'
    else
      render :new
    end
  end

  def update
    if @transport.update(transport_params)
      redirect_to @transport, notice: 'Transport was successfully updated.'
    else
      render :edit
    end
  end

  private
    def set_transport
      @transport = TransportSetting.find(params[:id])
    end

    def transport_params
      params[:transport_setting]
    end
end
