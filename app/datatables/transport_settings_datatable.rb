class TransportSettingsDatatable < Datatable
private
  def total_records
    @current_club.transport_settings.count
  end

  def total_entries
    transport_settings.total_entries
  end

  def data
    transport_settings.map do |transport_setting|
      [ 
        transport_setting.id,
        transport_setting.transport_i18n,
        (link_to(I18n.t(:show), @url_helpers.transport_setting_path(partner_prefix: @current_partner.prefix, club_prefix: @current_club.name, :id => transport_setting.id), :class => 'btn btn-mini') if @current_agent.can? :read, TransportSetting, @current_club.id).to_s + 
        (link_to(I18n.t(:edit), @url_helpers.edit_transport_setting_path(partner_prefix: @current_partner.prefix, club_prefix: @current_club.name, :id => transport_setting.id.to_s), :class => 'btn btn-mini') if @current_agent.can? :edit, TransportSetting, @current_club.id).to_s + 
        (link_to(I18n.t(:test_api_connection), @url_helpers.test_connection_transport_setting_path(partner_prefix: @current_partner.prefix, club_prefix: @current_club.name, id: transport_setting.id.to_s), class: 'btn btn-mini') if(transport_setting.store_spree? and @current_agent.can?(:edit, TransportSetting, @current_club.id))).to_s
      ]
    end
  end

  def transport_settings
    @transport_settings ||= fetch_transport_settings
  end

  def fetch_transport_settings
    transport_settings = @current_club.transport_settings.order("#{sort_column} #{sort_direction}")
    if params[:sSearch].present?
      transport_settings = transport_settings.where("transport like :search", search: "%#{params[:sSearch]}%")
    end
    transport_settings.page(page).per_page(per_page)
  end

  def sort_column
    TransportSetting.datatable_columns[params[:iSortCol_0].to_i]
  end
end     