class DomainsController < ApplicationController
  layout '2-cols'
  authorize_resource :domain

  # GET /domains
  # GET /domains.json
  def index
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: DomainsDatatable.new(view_context,@current_partner)}
    end
  end
  
  # GET /domains/1
  def show
    @domain = Domain.find(params[:id])
  end

  # GET /domains/new
  def new
    @domain = Domain.new :partner => @current_partner
    @domain.club_id = params[:club_id] if params[:club_id]
    @clubs = Club.where(:partner_id => @current_partner)
  end

  # GET /domains/1/edit
  def edit
    @domain = Domain.find(params[:id])
    @clubs = Club.where(:partner_id => @current_partner)
  end

  # POST /domains
  def create
    @domain = Domain.new(:url => params[:domain][:url], :data_rights => params[:domain][:data_rights], :description => params[:domain][:description], :hosted => params[:domain][:hosted])
    @domain.partner = @current_partner
    @domain.club_id = params[:domain][:club_id]
    @clubs = Club.where(:partner_id => @current_partner)

    if @domain.save
      redirect_to domain_path(:id => @domain), notice: "The domain #{@domain.url} was successfully created."
    else
      render action: "new"
    end
  end

  # PUT /domains/1
  def update
    @domain = Domain.find(params[:id])
    @clubs = Club.where(:partner_id => @current_partner)
    
    if @domain.update_attributes(:url => params[:domain][:url], :data_rights => params[:domain][:data_rights], :description => params[:domain][:description], :hosted => params[:domain][:hosted]) && @domain.update_attribute(:club_id,params[:domain][:club_id])
      redirect_to domain_path(:id => @domain), notice: "The domain #{@domain.url} was successfully updated."
    else
      render action: "edit"
    end
  end

  # DELETE /domains/1
  def destroy
    @domain = Domain.find(params[:id])

    if @domain.destroy
      redirect_to domains_url
    else
      redirect_to domains_path(:id => @domain), :flash => { error: "The domain #{@domain.url} cannot be destroyed. You must have at least one domain."}
    end
  end
end
