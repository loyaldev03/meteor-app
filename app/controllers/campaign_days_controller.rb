class CampaignDaysController < ApplicationController
  before_filter :validate_club_presence

  def missing
    my_authorize! :list, CampaignDay, current_club.id
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: CampaignDaysDatatable.new(view_context, current_partner, current_club, nil, current_agent) }
    end
  end

  def edit
    my_authorize! :edit, CampaignDay, current_club.id
    @campaign_day = CampaignDay.find(params[:id])
    render partial: 'edit'
  end

  def update
    @campaign_day = CampaignDay.find(params[:id])
    if @campaign_day.update_attributes params.require(:campaign_day).permit(:spent, :converted, :reached)
      render json: { success: true, message: 'Campaign day #{@campaign_day.date} for Campaign #{@campaign_day.name} was update successfuly.' }
    else
      render json: { success: false, message: 'Campaign day was not updated. Error: #{@campaign_day.errors.messages}' }
    end
  rescue ActiveRecord::RecordNotFound
    render json: { success: false, message: 'Campaign day not found.' }
  end
end