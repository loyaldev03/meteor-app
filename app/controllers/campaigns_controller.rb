class CampaignsController < ApplicationController
  before_filter :validate_club_presence
  before_action :set_campaign, only: [:show, :edit, :update]
  before_action :sanitize_preference_groups, only: [:create, :update]

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
    @preference_groups = current_club.preference_groups.where(add_by_default: true).pluck(:id)
    if current_club.terms_of_memberships.first.present?
      @campaign = Campaign.new(club_id: current_club.id)
    else
      redirect_to campaigns_url, alert: 'Can not create a campaign without a Subscription plan.'
    end
  end

  def create
    my_authorize! :create, Campaign, current_club.id
    @campaign = current_club.campaigns.new(campaign_params)
    @campaign.set_preference_groups(params[:campaign][:preference_groups])

    if @campaign.save
      @preference_groups = @campaign.preference_groups.empty? ? current_club.preference_groups.where(add_by_default: true).pluck(:id) : @campaign.preference_groups.pluck(:id)
      redirect_to campaign_path(partner_prefix: current_partner.prefix, club_prefix: current_club.name, id: @campaign.id), notice: "The campaign #{@campaign.name} was successfully created."
    else
      render action: "new"
    end
  end

  def edit
    my_authorize! :edit, Campaign, @campaign.club_id
    @preference_groups = @campaign.preference_groups.pluck(:id)
  end

  def update
    my_authorize! :update, Campaign, @campaign.club_id
    @campaign.set_preference_groups(params[:campaign][:preference_groups])

    if @campaign.update campaign_params_on_update
      @preference_groups = @campaign.preference_groups.pluck(:id)
      redirect_to campaigns_url, notice: "Campaign <b>#{@campaign.name}</b> was updated succesfully.".html_safe
    else
      flash.now[:error] = "Campaign <b>#{@campaign.name}</b> was not updated.".html_safe
      render action: "edit"
    end
  end

  private

  def campaign_params
    params.require(:campaign).permit(:name, :landing_name, :enrollment_price, :transport, :audience, :campaign_type, :terms_of_membership_id, :initial_date, :finish_date, :utm_content, :utm_medium, :transport_campaign_id, :campaign_code, :delivery_date)
  end

  def sanitize_preference_groups
    params[:campaign][:preference_groups] = params[:campaign][:preference_groups].reject(&:empty?) if params[:campaign][:preference_groups]
  end

  def campaign_params_on_update
    if @campaign.can_edit_transport_id?
      params.require(:campaign).permit(:name, :initial_date, :finish_date, :transport_campaign_id, :delivery_date)
    else
      params.require(:campaign).permit(:name, :initial_date, :finish_date, :delivery_date)
    end
  end

  def set_campaign
    @campaign = Campaign.find(params[:id])
  end
end
