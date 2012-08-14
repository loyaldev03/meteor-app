class Admin::PartnersController < ApplicationController
  layout :set_layout
  authorize_resource :partner

  # GET /partners
  # GET /partners.json
  def index
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: PartnersDatatable.new(view_context) }
    end
  end

  # GET /partners/1
  # GET /partners/1.json
  def show
    @partner = Partner.find(params[:id])
  end

  # GET /partners/new
  # GET /partners/new.json
  def new
    @partner = Partner.new
    @domain = @partner.domains.build
  end

  # GET /partners/1/edit
  def edit
    @partner = Partner.find(params[:id])
  end

  # POST /partners
  # POST /partners.json
  def create
    @partner = Partner.new(params[:partner])
    if @partner.save
      redirect_to admin_partner_path(@partner), notice: "The partner #{@partner.prefix} - #{@partner.name} was successfully created."
    else
      render action: "new"
    end
  end

  # PUT /partners/1
  # PUT /partners/1.json
  def update
    @partner = Partner.find(params[:id])
    if @partner.update_attributes(params[:partner])
      redirect_to admin_partner_path(@partner), notice: "The partner #{@partner.prefix} - #{@partner.name} was successfully updated." 
    else
      render action: "edit"
    end
  end

  # DELETE /partners/1
  # DELETE /partners/1.json
  def destroy
    @partner = Partner.find(params[:id])
    @partner.destroy
    redirect_to admin_partners_url
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

