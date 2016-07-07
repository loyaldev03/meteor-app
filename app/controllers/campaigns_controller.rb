class CampaignsController < ApplicationController
  before_filter :validate_club_presence

  def index
    my_authorize! :list, Campaign, current_club.id
    respond_to do |format|
      format.html
      format.json { render json: CampaignDatatable.new(view_context,@current_partner,@current_club,@current_user,@current_agent)}
    end 
  end

  def show
    # fill in code
  end

  def new
    @campaign = Campaign.new(club_id: current_club.id)
  end

  def create
    # fill in code
  end

  def edit
    # fill in code
  end

  def update
    # fill in code
  end

end