class CampaignDaysController < ApplicationController
  before_filter :validate_club_presence
  before_filter :check_authentification

  def index
  end

  def search_result
    start_date = (params[:from].blank? ? 1.week.ago : params[:from]).to_date
    end_date   = (params[:to].blank? ? Time.zone.now : params[:to]).to_date
    if start_date > end_date
      render status: 400, json: {code: 100, message: I18n.t("errors.wrong_data", errors: I18n.t("errors.date.end_greater_than_start"))}
      return
    end
    campaign_ids  = current_club.campaigns.by_transport(params[:transport]).ids
    campaign_days = CampaignDay.where(campaign_id: campaign_ids, date: start_date..end_date)
    render json: campaign_days
  end


  private
    def check_authentification
      my_authorize! :manage, CampaignDay, current_club.id
    end
end