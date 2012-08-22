class DomainsDatatable < Datatable


private

  def total_records
    Domain.count
  end

  def total_entries
    domains.total_entries
  end

  def data
    domains.map do |domain|
      [
        link_to(domain.id, @url_helpers.domain_path(:partner_prefix=> @current_partner.prefix, :id => domain.id)),
        domain.url,
        domain.description,
        domain.data_rights,
        domain.hosted,
        I18n.l(domain.created_at,:format=>:long),
        link_to(I18n.t(:edit),@url_helpers.edit_domain_path(:partner_prefix=> @current_partner.prefix, :id => domain.id), :class => 'btn btn-mini')+' '+
        link_to(I18n.t(:destroy),@url_helpers.domain_path(:partner_prefix=> @current_partner.prefix, :id => domain.id),
                      :method => :delete, 
                      :confirm => I18n.t("are_you_sure"),
                      :class => 'btn btn-mini btn-danger')
      ]
    end
  end

  def domains
    @domains ||= fetch_domains
  end

  def fetch_domains
    domains = Domain.where(:partner_id => @current_partner.id).order("#{sort_column} #{sort_direction}")
    domains = domains.page(page).per_page(per_page)
    if params[:sSearch].present?
      domains = domains.where("id like :search or email like :search or username like :search", search: "%#{params[:sSearch]}%")
    end
    domains
  end

  def sort_column
    Domain.datatable_columns[params[:iSortCol_0].to_i]
  end
end    