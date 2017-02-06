class Campaigns::ProductsController < ApplicationController
  before_filter :validate_club_presence
  before_action :set_campaign

  def show
    my_authorize! :manage, @campaign, @campaign.club_id
  end

  def edit
    my_authorize! :manage, @campaign, @campaign.club_id
  end

  def available
    my_authorize! :manage, @campaign, @campaign.club_id
    respond_to do |format|
      datatable = CampaignProductsAvailableDatatable.new(view_context, current_partner, current_club, nil, current_agent)
      datatable.campaign = @campaign
      format.json { render json: datatable }
    end
  rescue ActionController::UnknownFormat
    # Do not create an user story
  end

  def assigned
    my_authorize! :manage, @campaign, @campaign.club_id
    respond_to do |format|
      datatable = CampaignProductsDatatable.new(view_context, current_partner, current_club, nil, current_agent)
      datatable.campaign = @campaign
      format.json { render json: datatable }
    end
  rescue ActionController::UnknownFormat
    # Do not create an user story
  end

  def assign
    my_authorize! :manage, @campaign, @campaign.club_id
    product = Product.find(params[:product_id])
    if product.image_url.to_s.present?
      @campaign.products << product
      render json: { success: true, message: t('activerecord.attributes.campaign_product.product_assigned') }
    else
      render json: { success: false, message: t('activerecord.attributes.campaign_product.product_without_image') }
    end
  rescue ActiveRecord::RecordNotFound
    render json: { success: false, message: t('activerecord.attributes.campaign_product.product_not_found') }
  rescue ActiveRecord::RecordInvalid
    render json: { success: false, message: @campaign.errors.full_messages.first }
  end

  def destroy
    my_authorize! :edit, @campaign, @campaign.club_id
    campaign_product = @campaign.campaign_products.find_by(product_id: params[:product_id])
    if campaign_product
      campaign_product.destroy
      render json: { success: true, message: t('activerecord.attributes.campaign_product.product_removed') }
    else
      render json: { success: false, message: t('activerecord.attributes.campaign_product.product_not_found') }
    end
  rescue ActiveRecord::RecordNotFound
    render json: { success: false, message: t('activerecord.attributes.campaign_product.product_not_found') }
  rescue ActiveRecord::RecordInvalid
    render json: { success: false, message: t('activerecord.attributes.campaign_product.product_already_removed') }
  end

  def edit_label
    my_authorize! :edit, @campaign, @campaign.club_id
    @product = Product.find_by(id: params[:product_id], club_id: current_club.id)
    @campaign_product = CampaignProduct.find_by(campaign_id: @campaign.id, product_id: @product.id)
    render partial: 'edit_label'
  rescue ActiveRecord::RecordNotFound
    render json: { success: false, message: t('activerecord.attributes.campaign_product.product_not_found') }
  end

  def label
    my_authorize! :edit, @campaign, @campaign.club_id
    @campaign_product = CampaignProduct.find(params[:id])
    if @campaign_product.update_attributes params.require(:campaign_product).permit(:label)
      render json: { success: true, message: "Label for #{@campaign_product.product.name} for Campaign #{@campaign_product.campaign.name} was set successfuly." }
    else
      render json: { success: false, message: "Label was not updated. Error: #{@campaign_product.errors.messages}" }
    end
  rescue ActiveRecord::RecordNotFound
    render json: { success: false, message: t('activerecord.attributes.campaign_product.product_not_found') }
  end

  private

  def set_campaign
    @campaign = Campaign.find(params[:campaign_id])
  end
end
