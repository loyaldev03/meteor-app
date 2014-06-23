class ClubsController < ApplicationController
  layout '2-cols'

  def test_api_connection
    club = Club.find(params[:club_id])
    my_authorize!(:test_api_connection, Club, club.id)
    club.test_connection_to_api!
    flash[:notice] = "Phoenix can connect to the remote API correctly."
  rescue
    flash[:error] = "There was an error while connecting to the remote API. " + $!.to_s
  ensure
    redirect_to club_path(id: club.id)
  end  

  # GET /clubs
  # GET /clubs.json
  def index
    my_authorize_action_within_clubs!(:list, Club, @current_partner.clubs.collect(&:id))
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: ClubsDatatable.new(view_context,@current_partner,nil,nil,@current_agent) }
    end
  end

  # GET /clubs/1
  def show
    my_authorize!(:show, Club, params[:id])
    @club = Club.find(params[:id])
    @drupal_domain = Domain.find(@club.drupal_domain_id) if @club.drupal_domain_id
  end

  # GET /clubs/new
  def new
    my_authorize!(:new, Club)
    @club = Club.new
  end

  # GET /clubs/1/edit
  def edit
    my_authorize!(:show, Club, params[:id])
    @club = Club.find(params[:id])
  end

  # POST /clubs
  def create
    my_authorize!(:create, Club)
    @club = Club.new(params[:club])
    unless check_domain_belongs_to_partner(params[:club][:drupal_domain_id])
      flash.now[:error] = "Agent can't assign domain. Domain not available."
      render action: "new" 
    else
      @club.partner = @current_partner
      if @club.save
        redirect_to club_path(:id => @club), notice: "The club #{@club.name} was successfully created."
      else
        render action: "new" 
      end
    end
  end

  # PUT /clubs/1
  def update
    my_authorize!(:show, Club, params[:id])
    @club = Club.find(params[:id])
    unless check_domain_belongs_to_partner(params[:club][:drupal_domain_id])
      flash.now[:error] = "Agent can't assign domain. Domain not available."
      render action: "edit" 
    else
      if @club.update_attributes(params[:club])
        redirect_to club_path(:partner_prefix => @current_partner.prefix, :id => @club.id), notice: "The club #{@club.name} was successfully updated."
      else
        render action: "edit"
      end
    end
  end

  # DELETE /clubs/1
  def destroy
    my_authorize!(:show, Club)
    @club = Club.find(params[:id])
    if @club.destroy
      redirect_to clubs_url, notice: "Club #{@club.name} was successfully destroyed"
    else
      flash[:error] = "Club #{@club.name} was not destroyed."
      redirect_to clubs_url
    end 
  end


  def check_domain_belongs_to_partner(drupal_domain_id)
    valid = true
    if drupal_domain_id
      domain = Domain.find(drupal_domain_id)
      if domain.partner_id == @current_partner.id
        unless @current_agent.has_global_role? and domain.club 
          clubs_id = @current_agent.clubs.where("partner_id = ? and club_roles.role = 'admin'", @current_partner.id).collect(&:id)
          valid = false unless clubs_id.include?(domain.club_id)
        end
      else
        valid = false
      end
    end
    valid
  end
end

