class DomainsDatatable < Datatable

private

  def total_records
    Domain.where(partner_id: @current_partner.id).count
  end

  def total_entries
    domains.total_entries
  end

  def data
    domains.map do |domain|
      [
        domain.id,
        domain.url,
        domain.description,
        domain.data_rights,
        domain.hosted,
        (link_to(I18n.t(:show), @url_helpers.domain_path(:partner_prefix=> @current_partner.prefix, :id => domain.id), :class => 'btn btn-mini') if @current_agent.can? :read, Domain, domain.club_id).to_s+
        (link_to(I18n.t(:edit),@url_helpers.edit_domain_path(:partner_prefix=> @current_partner.prefix, :id => domain.id), :class => 'btn btn-mini') if @current_agent.can? :edit, Domain, domain.club_id).to_s+
        (link_to(I18n.t(:destroy),@url_helpers.domain_path(:partner_prefix=> @current_partner.prefix, :id => domain.id),
                      :method => :delete, 
                      :data => {:confirm => I18n.t("are_you_sure")},
                      :class => 'btn btn-mini btn-danger')if @current_agent.can? :delete, Domain, domain.club_id).to_s
      ]
    end
  end

  def domains
    @domains ||= fetch_domains
  end

  def fetch_domains
    domains = if @current_agent.has_global_role?
      Domain.where(:partner_id => @current_partner.id).order("#{sort_column} #{sort_direction}")
    else
      Domain.where("partner_id = ? and club_id in (?)", @current_partner.id, @current_agent.clubs_related_id_list("admin")).order("#{sort_column} #{sort_direction}")
    end    
    domains = domains.page(page).per_page(per_page)
    if params[:sSearch].present?
      domains = domains.where("id like :search or url like :search", search: "%#{params[:sSearch]}%")
    end
    domains
  end

  def sort_column
    Domain.datatable_columns[params[:iSortCol_0].to_i]
  end
end    