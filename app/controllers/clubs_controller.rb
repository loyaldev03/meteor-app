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
  # GET /clubs/1.json
  def show
    @club = Club.find(params[:id])
  end

  # GET /clubs/new
  # GET /clubs/new.json
  def new
    @club = Club.new
  end

  # GET /clubs/1/edit
  def edit
    @club = Club.find(params[:id])
  end

  # POST /clubs
  # POST /clubs.json
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
  # PUT /clubs/1.json
  def update
    @club = Club.find(params[:id])
    if @club.update_attributes(params[:club])
      redirect_to club_path(:partner_prefix => @current_partner.prefix, :id => @club.id), notice: "The club #{@club.name} was successfully updated."
    else
      render action: "edit"
    end
  end

  # DELETE /clubs/1
  # DELETE /clubs/1.json
  def destroy
    @club = Club.find(params[:id])
    @club.destroy
    redirect_to clubs_url 
  end
end
