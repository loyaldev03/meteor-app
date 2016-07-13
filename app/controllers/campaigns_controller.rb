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
    my_authorize! :read, Campaign, current_club.id
    # fill in code
  end

  def new
    my_authorize! :new, Campaign, current_club.id
    @campaign = Campaign.new(club_id: current_club.id)
    @terms_of_memberships = current_club.terms_of_memberships
  end

  def create
    my_authorize! :create, Campaign, current_club.id
    @campaign = Campaign.new club_id: current_club.id
    @campaign.set_data(campaign_params)

    if @campaign.save
      redirect_to campaign_path(partner_prefix: current_partner.prefix, club_prefix: current_club.name, id: @campaign), notice: "The campaign #{@campaign.name} was successfully created."
    else
      @terms_of_memberships = current_club.terms_of_memberships
      render action: "new"
    end
  end

  def edit
    my_authorize! :edit, Campaign, current_club.id
    # fill in code
  end

  def update
    my_authorize! :update, Campaign, current_club.id
    # fill in code
  end

  private
    def campaign_params
      params.require(:campaign).permit(:name, :transport, :marketing_code, :campaign_type, :terms_of_membership_id, :initial_date, :finish_date, :campaign_medium_version, :transport_campaign_id, :fulfillment_code)
    end

end