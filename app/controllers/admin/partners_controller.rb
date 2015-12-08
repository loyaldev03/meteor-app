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
    @partner = Partner.new(params[:partner])
    if @partner.save
      redirect_to admin_partner_path(@partner), notice: "The partner #{@partner.prefix} - #{@partner.name} was successfully created."
    else
      render action: "new"
    end
  end

  # PUT /partners/1
  def update
    @partner = Partner.find(params[:id])
    if @partner.update_attributes(params[:partner])
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

end

