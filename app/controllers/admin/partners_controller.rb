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
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @partner }
    end
  end

  # GET /partners/new
  # GET /partners/new.json
  def new
    @partner = Partner.new
    @domain = @partner.domains.build
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @partner }
    end
  end

  # GET /partners/1/edit
  def edit
    @partner = Partner.find(params[:id])
    authorize! :update, @partner
  end

  # POST /partners
  # POST /partners.json
  def create
    @partner = Partner.new(params[:partner])
    respond_to do |format|
      if @partner.save
        format.html { redirect_to [ :admin, @partner ], notice: "The partner #{@partner.prefix} - #{@partner.name} was successfully created." }
        format.json { render json: @partner, status: :created, location: @partner }
      else
        format.html { render action: "new" }
        format.json { render json: @partner.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /partners/1
  # PUT /partners/1.json
  def update
    @partner = Partner.find(params[:id])
    respond_to do |format|
      if @partner.update_attributes(params[:partner])
        format.html { redirect_to [ :admin, @partner ], notice: "The partner #{@partner.prefix} - #{@partner.name} was successfully updated." }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @partner.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /partners/1
  # DELETE /partners/1.json
  def destroy
    @partner = Partner.find(params[:id])
    @partner.destroy
    respond_to do |format|
      format.html { redirect_to admin_partners_url }
      format.json { head :no_content }
    end
  end

  def dashboard
    @partner = @current_partner
    authorize! :read, @partner
    @domains = Domain.where(:partner_id => @current_partner)
  end

  private
    def set_layout
      params[:action] == 'dashboard' ? '2-cols' : 'application'
    end

end

