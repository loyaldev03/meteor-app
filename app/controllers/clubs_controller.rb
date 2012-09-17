class ClubsController < ApplicationController
  layout '2-cols'
  authorize_resource :club

  # GET /clubs
  # GET /clubs.json
  def index
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: ClubsDatatable.new(view_context,@current_partner,nil,nil,@current_agent) }
    end
  end

  # GET /clubs/1
  def show
    @club = Club.find(params[:id])
  end

  # GET /clubs/new
  def new
    @club = Club.new
  end

  # GET /clubs/1/edit
  def edit
    @club = Club.find(params[:id])
  end

  # POST /clubs
  def create
    @club = Club.new(params[:club])
    @club.partner = @current_partner
    if @club.save
      redirect_to club_path(:id => @club), notice: "The club #{@club.name} was successfully created."
    else
      render action: "new" 
    end
  end

  # PUT /clubs/1
  def update
    @club = Club.find(params[:id])
    if @club.update_attributes(params[:club])
      redirect_to club_path(:partner_prefix => @current_partner.prefix, :id => @club.id), notice: "The club #{@club.name} was successfully updated."
    else
      render action: "edit"
    end
  end

  # DELETE /clubs/1
  def destroy
    @club = Club.find(params[:id])
    if @club.destroy
      redirect_to clubs_url, notice: "Club #{@club.name} was successfully destroyed"
    else
      flash[:error] = "Club #{@club.name} was not destroyed."
    end
  end
end
