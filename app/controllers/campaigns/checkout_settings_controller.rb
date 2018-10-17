class Campaigns::CheckoutSettingsController < ApplicationController
  before_action :validate_club_presence
  before_action :set_campaign
  before_action :local_authorize

  FIELDS = %i[
    checkout_page_bonus_gift_box_content
    checkout_page_footer
    css_style
    duplicated_page_content
    error_page_content
    result_page_footer
    thank_you_page_content
    header_image
    result_pages_image
  ].freeze

  layout '2-cols'

  def show; end

  def edit; end

  def update
    if @campaign.update checkout_settings_params
      redirect_to campaign_checkout_settings_path(
        partner_prefix: current_partner.prefix,
        club_prefix: current_club.name
      ), notice: t('activerecord.attributes.checkout_settings.settings_update_success')
    else
      redirect_to campaign_checkout_settings_edit_path(
        partner_prefix: current_partner.prefix,
        club_prefix: current_club.name,
        campaign_id: @campaign.id
      ), flash: { error: t('activerecord.attributes.checkout_settings.settings_update_error') }
    end
  end

  def destroy
    nil_values = FIELDS.each_with_object({}) { |field, hash| hash[field] = nil }
    if @campaign.update nil_values
      flash[:notice] = t('activerecord.attributes.checkout_settings.all_settings_clear_success')
    else
      flash[:error] = t('activerecord.attributes.checkout_settings.all_settings_clear_error')
    end
    redirect_to campaign_checkout_settings_path(
      partner_prefix: current_partner.prefix,
      club_prefix: current_club.name
    )
  end

  def remove_image
    return unless params[:image_name].present?
    case params[:image_name]
    when 'header_image'
      @campaign.header_image = nil
    when 'result_pages_image'
      @campaign.result_pages_image = nil
    end
    if @campaign.save
      flash[:notice] = t('activerecord.attributes.checkout_settings.image_remove_success', image_name: params[:image_name])
    else
      flash[:error] = t('activerecord.attributes.checkout_settings.image_remove_error', image_name: params[:image_name])
    end
    redirect_to campaign_checkout_settings_path(
      partner_prefix: current_partner.prefix,
      club_prefix: current_club.name
    )
  end

  private

  def set_campaign
    @campaign = current_club.campaigns.find(params[:campaign_id])
  end

  def checkout_settings_params
    params.require(:campaign).permit(FIELDS)
  end

  def local_authorize
    my_authorize! :manage, @campaign, current_club.id
  end
end
