class MyClubsDatatable < Datatable
private

  def total_records
    if @current_agent.has_role? 'admin'
      Club.where("deleted_at is null").count
    else
      @current_agent.clubs.count
    end
  end

  def total_entries
    clubs.total_entries
  end

  def data
    clubs.map do |club|
      [
        club.id,
        club.name, 
        club.description,
        club.members.count,
        (link_to(I18n.t('activerecord.model.members'), @url_helpers.members_path(club.partner.prefix, club.name), :class => 'btn btn-mini') if @current_agent.can? :read, Member, club.id).to_s+
        (link_to(I18n.t('activerecord.model.products'), @url_helpers.products_path(club.partner.prefix, club.name), :class => 'btn btn-mini') if @current_agent.can? :read, Product, club.id).to_s+
        (link_to(I18n.t('activerecord.model.fulfillments'), @url_helpers.fulfillments_index_path(club.partner.prefix, club.name), :class => 'btn btn-mini') if @current_agent.can? :read, Fulfillment, club.id).to_s+
        (link_to(I18n.t('activerecord.model.fulfillment_files'), @url_helpers.list_fulfillment_files_path(club.partner.prefix, club.name), :class => 'btn btn-mini') if @current_agent.can? :report, Fulfillment, club.id).to_s
      ]
    end
  end

  def clubs
    @clubs ||= fetch_clubs
  end

  def fetch_clubs
    unless @current_agent.has_global_role?
      clubs = @current_agent.clubs.order("#{sort_column} #{sort_direction}")
    else
      clubs = Club.where("deleted_at is null").order("#{sort_column} #{sort_direction}")
    end
    clubs = clubs.page(page).per_page(per_page)
    if params[:sSearch].present?
      clubs = clubs.where("id like :search or name like :search", search: "%#{params[:sSearch]}%")
    end
    clubs
  end

  def sort_column
    Club.datatable_columns[params[:iSortCol_0].to_i]
  end
end    