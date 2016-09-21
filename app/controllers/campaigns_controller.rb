class CampaignsController < ApplicationController
  before_filter :validate_club_presence
  before_action :set_campaign, only: [:show, :edit, :update]

  def index
    my_authorize! :list, Campaign, current_club.id
    respond_to do |format|
      format.html
      format.json { render json: CampaignDatatable.new(view_context, current_partner, current_club, current_user, current_agent)}
    end 
  end

  def show
    my_authorize! :read, Campaign, @campaign.club_id
  end

  def new
    my_authorize! :new, Campaign, current_club.id
    if current_club.terms_of_memberships.first.present?
      @campaign = Campaign.new(club_id: current_club.id)
    else
      redirect_to campaigns_url, alert: 'Can not create a campaign without a Subscription plan.'
    end
  end

  def create
    my_authorize! :create, Campaign, current_club.id
    @campaign = Campaign.new(campaign_params)
    @campaign.club_id = current_club.id
    if @campaign.save
      redirect_to campaign_path(partner_prefix: current_partner.prefix, club_prefix: current_club.name, id: @campaign), notice: "The campaign #{@campaign.name} was successfully created."
    else
      render action: "new"
    end
  end

  def edit
    my_authorize! :edit, Campaign, @campaign.club_id
  end

  def update
    my_authorize! :update, Campaign, @campaign.club_id
    if @campaign.update campaign_params_on_update
      redirect_to campaigns_url, notice: "Campaign <b>#{@campaign.name}</b> was updated succesfully.".html_safe
    else
      render action: "edit", alert: "Campaign <b>#{@campaign.name}</b> was not updated.".html_safe
    end
  end

  private
    def campaign_params
      params.require(:campaign).permit(:name, :landing_name, :enrollment_price, :transport, :audience, :campaign_type, :terms_of_membership_id, :initial_date, :finish_date, :utm_content, :transport_campaign_id, :campaign_code)
    end

    def campaign_params_on_update
      if @campaign.can_edit_transport_id?
        params.require(:campaign).permit(:name, :initial_date, :finish_date, :transport_campaign_id)
      else
        params.require(:campaign).permit(:name, :initial_date, :finish_date)
      end
    end

    def set_campaign
      @campaign = Campaign.find(params[:id])
    end
end