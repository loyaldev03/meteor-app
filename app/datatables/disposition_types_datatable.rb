class DispositionTypesDatatable < Datatable
private

  def total_records
    @current_club.disposition_types.count
  end

  def total_entries
    disposition_types.total_entries
  end

  def data
    disposition_types.map do |disposition_type|
      [
        disposition_type.id,
        disposition_type.name, 
        (link_to(I18n.t(:edit),@url_helpers.edit_disposition_type_path(:partner_prefix=> @current_partner.prefix, :club_prefix => @current_club.name, :id => disposition_type.id ), :class => 'btn btn-mini')if @current_agent.can? :edit, DispositionType, @current_club.id)
      ]
    end
  end

  def disposition_types
    disposition_types ||= fetch_disposition_types
  end

  def fetch_disposition_types
    disposition_types = @current_club.disposition_types.order("#{sort_column} #{sort_direction}")
    disposition_types = disposition_types.page(page).per_page(per_page)
    if params[:sSearch].present?
      disposition_types = disposition_types.where("id like :search or name like :search", search: "%#{params[:sSearch]}%")
    end
    disposition_types
  end

  def sort_column
    DispositionType.datatable_columns[params[:iSortCol_0].to_i]
  end
end    