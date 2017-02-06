class Api::CampaignsController < ApplicationController
  skip_before_filter :verify_authenticity_token

  respond_to :json

  ##
  # Returns the campaign data to be used in landing pages
  #
  # @resource /api/v1/campaigns/:id/metadata
  # @action POST
  #
  # @required [String] api_key Agent's authentication token. This token allows
  # us to check if the agent is allowed to request this action.
  # @response_field [String] code Code related to the method result.
  # @response_field [String] message Shows the method errors.
  # @response_field [Hash] campaign Generic campaign data (such as the title)
  # @response_field [Hash] products Available products for this campaign
  # @response_field [Hash] preferences Preferences assigned to this campaign
  #
  # @example_request
  #   curl -v -k -X POST -d "api_key=yS6PAUwgbt81yR3dZCxP" http://127.0.0.1:3000/api/v1/campaigns/1/metadata
  # @example_request_description Example of valid request.
  #
  # @example_response
  #   {"code":"000","campaign":[{"title":"Daily Deals Join Now "}],"products":[{"name":"PRODUCTNAME90","sku":"PRODUCTSKU90","id":90},{"name":"PRODUCTNAME94","sku":"PRODUCTSKU94","id":94},{"name":"PRODUCTNAME98","sku":"PRODUCTSKU98","id":98}],"preferences":[{"group_code":"test","id":1,"name":"John"},{"group_code":"test","id":2,"name":"Paul"},{"group_code":"test","id":3,"name":"Ringo"},{"group_code":"test","id":4,"name":"George"}]}
  # @example_response_description Example response to valid request.
  #
  def metadata
    @campaign = Campaign.find_by!(slug: params[:id])
    my_authorize! :api_campaign_get_data, @campaign, @campaign.club_id
    products = get_products
    if @campaign.active? && products.first.present?
      render json: {
        code: Settings.error_codes.success,
        campaign: get_campaign,
        get_products: products,
        get_preferences: get_preferences
      }
    else
      render json: {
        code: Settings.error_codes.campaign_not_active,
        jump_url: @campaign.club.unavailable_campaign_url,
        message: I18n.t('error_messages.campaign_is_not_active')
      }
    end
  rescue ActiveRecord::RecordNotFound
    render json: {
      code: Settings.error_codes.not_found,
      message: 'Campaign not found.'
    }
  end

  private

  def get_campaign
    [{ title: @campaign.name, favicon_url: @campaign.club.favicon_url.url }]
  end

  def get_products
    @campaign.products.where('stock > ? OR allow_backorder = ?', 0, true).order(:weight).pluck(:id, "campaign_products.label as label", :image_url, :sku).map { |id, label, image_url, sku| { id: id, name: label, sku: sku, image_url: image_url } }
  end

  def get_preferences
    preferences = Array.new
    @campaign.preference_groups.includes(:preferences).each do |pg|
      pg.preferences.select(:id, :name).each do |p|
        preferences << { group_code: pg.code, id: p.id, name: p.name }
      end
    end
    preferences
  end
end
