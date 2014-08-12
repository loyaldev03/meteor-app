class DomainsController < ApplicationController
  layout '2-cols'
  before_filter :load_clubs_related, only: [ :new, :edit ]


  # GET /domains
  # GET /domains.json
  def index
    my_authorize_action_within_clubs!(:list, Domain, @current_partner.clubs.collect(&:id))
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: DomainsDatatable.new(view_context,@current_partner,nil,nil,@current_agent)}
    end
  end
  
  # GET /domains/1
  def show
    @domain = Domain.find(params[:id])
    my_authorize!(:show, Domain, @domain.club_id)
  end

  # GET /domains/new
  def new
    my_authorize_action_within_clubs!(:new, Domain, @current_partner.clubs.collect(&:id))
    @domain = Domain.new :partner => @current_partner
    @domain.club_id = params[:club_id] if params[:club_id]
  end

  # GET /domains/1/edit
  def edit
    @domain = Domain.find(params[:id])
    my_authorize!(:edit, Domain, @domain.club_id)
  end

  # POST /domains
  def create
    @domain = Domain.new(:url => params[:domain][:url], :data_rights => params[:domain][:data_rights], :description => params[:domain][:description], :hosted => params[:domain][:hosted])
    @domain.partner = @current_partner
    @domain.club_id = params[:domain][:club_id]

    my_authorize!(:create, Domain, @domain.club_id)
    if @domain.save
      redirect_to domain_path(:id => @domain), notice: "The domain #{@domain.url} was successfully created."
    else
      load_clubs_related
      render action: "new"
    end
  end

  # PUT /domains/1
  def update
    @domain = Domain.find(params[:id])
    my_authorize!(:update, Domain, @domain.club_id)
    @domain.url = params[:domain][:url]
    @domain.data_rights = params[:domain][:data_rights]
    @domain.description = params[:domain][:description]
    @domain.hosted = params[:domain][:hosted]
    if not params[:domain][:club_id].nil? and @domain.club.nil?
      @domain.club_id = params[:domain][:club_id]       
    end
    if @domain.save
      redirect_to domain_path(:id => @domain), notice: "The domain #{@domain.url} was successfully updated."
    else
      load_clubs_related
      render action: "edit"
    end
  end

  # DELETE /domains/1
  def destroy
    @domain = Domain.find(params[:id])
    my_authorize!(:destroy, Domain, @domain.club_id)

    if @domain.destroy
      redirect_to domains_url, notice: "Domain #{@domain.url} was successfully destroyed"
    else
      redirect_to domains_path(:id => @domain), :flash => { error: @domain.errors[:base].first[:error] }
    end
  end

  def load_clubs_related
    @clubs = @current_agent.has_global_role? ? Club.select("id,name").where(:partner_id => @current_partner) : @current_agent.clubs.where("partner_id = ? and club_roles.role = 'admin'", @current_partner.id)
  end
end
