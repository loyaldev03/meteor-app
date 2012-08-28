class MyClubsDatatable < Datatable
private

  def total_records
    if @current_agent.has_role? 'admin'
      Club.where("deleted_at is null").count
    else
      Club.joins(:club_roles).where("agent_id = ?",@current_agent).count
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
        (link_to(I18n.t('activerecord.model.fulfillments'), @url_helpers.fulfillments_index_path(club.partner.prefix, club.name), :class => 'btn btn-mini')if @current_agent.can? :read, Fulfillment)
      ]
    end
  end

  def clubs
    @clubs ||= fetch_clubs
  end

  def fetch_clubs
    if @current_agent.has_role? 'admin'
      clubs = Club.where("deleted_at is null").order("#{sort_column} #{sort_direction}")
    else
      clubs = Club.joins(:club_roles).where("agent_id = ?",@current_agent).order("#{sort_column} #{sort_direction}")
      clubs = clubs.uniq
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