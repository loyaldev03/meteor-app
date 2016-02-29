class Admin::PartnersController < ApplicationController
  layout :set_layout
  authorize_resource :partner

  # GET /partners
  def index
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: PartnersDatatable.new(view_context,nil,nil,nil,@current_agent) }
    end
  end

  # GET /partners/1
  def show
    @partner = Partner.find(params[:id])
  end

  # GET /partners/new
  def new
    @partner = Partner.new
    @domain = @partner.domains.build
  end

  # GET /partners/1/edit
  def edit
    @partner = Partner.find(params[:id])
  end

  # POST /partners
  def create
    @partner = Partner.new(partner_params)
    if @partner.save
      redirect_to admin_partner_path(@partner), notice: "The partner #{@partner.prefix} - #{@partner.name} was successfully created."
    else
      render action: "new"
    end
  end

  # PUT /partners/1
  def update
    @partner = Partner.find(params[:id])
    if @partner.update partner_params
      redirect_to admin_partner_path(@partner), notice: "The partner #{@partner.prefix} - #{@partner.name} was successfully updated." 
    else
      render action: "edit"
    end
  end

  def dashboard
    @partner = @current_partner
    @domains = Domain.where(:partner_id => @current_partner)
  end

  private
    def set_layout
      params[:action] == 'dashboard' ? '2-cols' : 'application'
    end

    def partner_params
      params.require(:partner).permit(:prefix, :name, :contract_uri, :website_url, :description, domains_attributes: [:url, :description, :data_rights, :hosted])
    end
end

