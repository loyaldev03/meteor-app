class CampaignsController < ApplicationController
  before_filter :validate_club_presence
  before_action :set_campaign, only: [:show, :edit, :update]
  before_action :set_fulfillment_codes, only: [:new, :edit]

  def index
    my_authorize! :list, Campaign, current_club.id
    respond_to do |format|
      format.html
      format.json { render json: CampaignDatatable.new(view_context,@current_partner,@current_club,@current_user,@current_agent)}
    end 
  end

  def show
    my_authorize! :read, Campaign, current_club.id
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
    @terms_of_memberships = current_club.terms_of_memberships
  end

  def update
    my_authorize! :update, Campaign, current_club.id
    if @campaign.update campaign_params
      flash[:notice] = "Campaign <b>#{@campaign.name}</b> was updated succesfully".html_safe
      redirect_to campaigns_url
    else
      flash[:error] = "Campaign <b>#{@campaign.name}</b> was not updated".html_safe
      redirect_to campaigns_url
    end
  end

  private
    def campaign_params
      params.require(:campaign).permit(:name, :enrollment_price, :transport, :marketing_code, :campaign_type, :terms_of_membership_id, :initial_date, :finish_date, :campaign_medium_version, :transport_campaign_id, :fulfillment_code)
    end

    def set_campaign
      @campaign = Campaign.find(params[:id])
    end

    def set_fulfillment_codes
      @fulfillment_codes = ['New automatic code']
      current_club.campaigns.each do |c|
        @fulfillment_codes << c.fulfillment_code
      end
      @fulfillment_codes.uniq!
    end
end