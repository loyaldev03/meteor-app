class CampaignsController < ApplicationController
  before_filter :validate_club_presence
  before_action :set_campaign, only: [:show, :edit, :update]
  before_action :set_toms, only: [:new, :create, :edit]
  before_action :set_fulfillment_codes, only: [:new, :create, :show, :edit, :update]

  def index
    my_authorize! :list, Campaign, current_club.id
    respond_to do |format|
      format.html
      format.json { render json: CampaignDatatable.new(view_context, current_partner, current_club, current_user, current_agent)}
    end 
  end

  def show
    my_authorize! :read, Campaign, @campaign.club.id
  end

  def new
    my_authorize! :new, Campaign, current_club.id
    if @terms_of_memberships.first.present?
      @campaign = Campaign.new(club_id: current_club.id)
    else
      flash[:error] = "Can not create a campaign without a Subscription plan."
      redirect_to campaigns_url
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
    my_authorize! :edit, Campaign, @campaign.club.id
  end

  def update
    my_authorize! :update, Campaign, @campaign.club.id
    if @campaign.update campaign_params_on_update
      redirect_to campaigns_url, notice: "Campaign <b>#{@campaign.name}</b> was updated succesfully".html_safe
    else
      redirect_to campaigns_url, error: "Campaign <b>#{@campaign.name}</b> was not updated".html_safe
    end
  end

  private
    def campaign_params
      params.require(:campaign).permit(:name, :enrollment_price, :transport, :marketing_code, :campaign_type, :terms_of_membership_id, :initial_date, :finish_date, :campaign_medium_version, :transport_campaign_id, :fulfillment_code)
    end

    def campaign_params_on_update
      params.require(:campaign).permit(:name, :initial_date, :finish_date)
    end

    def set_campaign
      @campaign = Campaign.find(params[:id])
    end

    def set_toms
      @terms_of_memberships = current_club.terms_of_memberships.select(:id, :name)
    end

    def set_fulfillment_codes
      @fulfillment_codes = ['New automatic code']
      current_club.campaigns.pluck(:fulfillment_code).each do |code|
        @fulfillment_codes << code
      end
      @fulfillment_codes.uniq!
    end
end