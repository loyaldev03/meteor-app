class ClubsDatatable < Datatable
private

  def total_records
    Club.find_all_by_partner_id(@current_partner.id).count
  end

  def total_entries
    clubs.total_entries
  end

  def data
    clubs.map do |club|
      [
        club.id,
        club.name, 
        (club.description.nil? ? "" : club.description.truncate(30)),
        club.members.count,
        (link_to(I18n.t('show'), @url_helpers.club_path(:partner_prefix => @current_partner.prefix, :id => club.id), :class => 'btn btn-mini') if @current_agent.can? :read, Club).to_s+
        (link_to(I18n.t(:edit), @url_helpers.edit_club_path(:partner_prefix => @current_partner.prefix,:id => club.id), :class => 'btn btn-mini')if @current_agent.can? :update, Club).to_s+
        (link_to(I18n.t('activerecord.model.members'), @url_helpers.members_path(@current_partner.prefix, club.name), :class => 'btn btn-mini')if @current_agent.can? :read, Member, club.id).to_s+
        (link_to(I18n.t('activerecord.model.products'), @url_helpers.products_path(@current_partner.prefix, club.name), :class => 'btn btn-mini')if @current_agent.can? :read, Product,club.id ).to_s+
        (link_to(I18n.t('activerecord.model.fulfillments'), @url_helpers.fulfillments_index_path(@current_partner.prefix, club.name), :class => 'btn btn-mini')if @current_agent.can? :read, Fulfillment,club.id ).to_s+
        (link_to(I18n.t('activerecord.model.fulfillment_files'), @url_helpers.list_fulfillment_files_path(club.partner.prefix, club.name), :class => 'btn btn-mini') if @current_agent.can? :report, Fulfillment, club.id).to_s+
        (link_to(I18n.t(:destroy), @url_helpers.club_path(:partner_prefix => @current_partner.prefix, :id => club.id), :method => :delete,
                        :confirm => I18n.t("are_you_sure"),
                        :class => 'btn btn-mini btn-danger') if @current_agent.can? :update, Club).to_s
      ]
    end
  end

  def clubs
    @clubs ||= fetch_clubs
  end

  def fetch_clubs
    if @current_agent.has_role? 'admin'
      clubs = Club.where(:partner_id => @current_partner.id).order("#{sort_column} #{sort_direction}")
    else
      clubs = @current_agent.clubs.where(:partner_id => @current_partner.id).order("#{sort_column} #{sort_direction}")
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