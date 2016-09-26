class CampaignDatatable < Datatable

private
  def total_records
    @current_club.campaigns.count
  end

  def total_entries
    campaigns.total_entries
  end

  def data
    campaigns.map do |campaign|
      [ 
        campaign.id,
        campaign.name,
        campaign.campaign_type,
        campaign.transport,
        I18n.l(campaign.initial_date.to_date),
        (I18n.l(campaign.finish_date.to_date) if campaign.finish_date.present?),
        (link_to(I18n.t(:show), @url_helpers.campaign_path(partner_prefix: @current_partner.prefix, club_prefix: @current_club.name, :id => campaign.id), :class => 'btn btn-mini') if @current_agent.can? :read, Campaign, @current_club.id).to_s + 
        (link_to(I18n.t(:edit), @url_helpers.edit_campaign_path(partner_prefix: @current_partner.prefix, club_prefix: @current_club.name, :id => campaign.id.to_s), :class => 'btn btn-mini') if @current_agent.can? :edit, Campaign, @current_club.id).to_s
      ]
    end
  end

  def campaigns
    @campaigns ||= fetch_campaigns
  end

  def fetch_campaigns
    campaigns = @current_club.campaigns.order("#{sort_column} #{sort_direction}")
    if params[:sSearch].present?
      campaigns = campaigns.where("name like :search", search: "%#{params[:sSearch]}%")
    end
    campaigns.page(page).per_page(per_page)
  end

  def sort_column
    Campaign.datatable_columns[params[:iSortCol_0].to_i]
  end
end     