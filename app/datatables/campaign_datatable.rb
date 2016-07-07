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
        campaign.type,
        campaign.transport,
        I18n.l(file.start_date.to_date),
        I18n.l(file.finish_date.to_date)
      ]
    end
  end

  def campaigns
    @campaigns ||= fetch_campaigns
  end

  def fetch_campaigns
    campaigns = @current_club.campaigns
    if params[:sSearch].present?
      campaigns = campaigns.where("name = :search", search: "#{params[:sSearch].gsub(/\D/,'')}")
    end

    campaigns.page(page).per_page(per_page)
  end
end     