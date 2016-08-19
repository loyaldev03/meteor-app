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
        campaign_day.date,
        campaign_day.campaign.name,
        campaign_day.campaign.transport,
        campaign_day.spent,
        campaign_day.reached,
        campaign_day.converted,
        ((link_to(I18n.t(:edit), @url_helpers.edit_campaign_day_path(@current_partner.prefix, @current_club.name, campaign_day.id), :class => 'btn btn-mini', :id => 'edit', 'data-toggle' => 'custom-remote-modal', 'data-target' => '#campaignDayEditModal', 'data-date' => "#{campaign_day.date}")) if @current_agent.can? :edit, CampaignDay, @current_club.id).to_s
      ]
    end
  end

  def campaign_days
    @campaign_days ||= fetch_campaigns
  end

  def fetch_campaigns
    campaign_days = CampaignDay.includes(:campaign).
                                where(campaigns: {club_id: @current_club.id}).
                                where.not(campaigns: {transport: Campaign.transports.select{|x| Campaign::TRANSPORT_WHERE_NOT_ALLOWED_MANUAL_UPDATE.include? x}.values}).
                                missing.
                                order(sort_by)
    if params[:sSearch].present?
      campaign_days = campaign_days.where(campaigns: {transport: Campaign.transports[params[:sSearch]]})
    end
    campaign_days.page(page).per_page(per_page)
  end

  def sort_by
    sort_column = CampaignDay.datatable_columns[params[:iSortCol_0].to_i]
    sort_column == 'campaign' ? "name #{sort_direction}, date asc" : "#{sort_column} #{sort_direction}"
  end

end