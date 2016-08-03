class CampaignDaysDatatable < Datatable

private
  def total_records
    campaign_days.count
  end

  def total_entries
    campaign_days.total_entries
  end

  def data
    campaign_days.map do |campaign_day|
      [ 
        I18n.l(campaign_day.date,:format => :dashed),
        campaign_day.campaign.name,
        campaign_day.spent,
        campaign_day.reached,
        campaign_day.converted,
        ''
      ]
    end
  end

  def campaign_days
    @campaign_days ||= fetch_campaigns
  end

  def fetch_campaigns
    campaign_days = CampaignDay.includes(:campaign).where(campaigns: {club_id: @current_club.id}).missing.order("#{sort_column} #{sort_direction}")
    if params[:sSearch].present?
      campaign_days = campaign_days.where(campaigns: {transport: Campaign.transports[params[:sSearch]]})
    end
    campaign_days.page(page).per_page(per_page)
  end

  def sort_column
    column = CampaignDay.datatable_columns[params[:iSortCol_0].to_i]
    column == 'campaign' ? 'name' : column
  end
end