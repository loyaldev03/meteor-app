class ClubsDatatable < Datatable
private

  def total_records
    Club.count
  end

  def total_entries
    clubs.total_entries
  end

  def data
    clubs.map do |club|
      [
        link_to(club.id, @url_helpers.club_path(:partner_prefix => @current_partner.prefix, :id => club.id)),
        club.name, 
        club.description,
        club.members.count,
        link_to(I18n.t('activerecord.model.members'), @url_helpers.members_path(@current_partner.prefix, club.name), :class => 'btn btn-mini')+
        link_to(I18n.t('activerecord.model.products'), @url_helpers.products_path(@current_partner.prefix, club.name), :class => 'btn btn-mini')+
        link_to(I18n.t(:edit), @url_helpers.edit_club_path(:partner_prefix => @current_partner.prefix,:id => club.id), :class => 'btn btn-mini')+
        link_to(I18n.t(:destroy), @url_helpers.club_path(:partner_prefix => @current_partner.prefix, :id => club.id), :method => :delete,
                        :confirm => I18n.t('.confirm', :default => I18n.t("helpers.links.confirm", :default => 'Are you sure?')),
                        :class => 'btn btn-mini btn-danger')
      ]
    end
  end

  def clubs
    @clubs ||= fetch_clubs
  end

  def fetch_clubs
    clubs = Club.where(:partner_id => @current_partner.id).order("#{sort_column} #{sort_direction}")
    clubs = clubs.page(page).per_page(per_page)
    if params[:sSearch].present?
      clubs = clubs.where("id like :search or email like :search or username like :search", search: "%#{params[:sSearch]}%")
    end
    clubs
  end

  def sort_column
    Club.datatable_columns[params[:iSortCol_0].to_i]
  end
end    