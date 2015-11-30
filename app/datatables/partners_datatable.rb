class PartnersDatatable < Datatable

private

  def total_records
    Partner.count
  end

  def total_entries
    partners.total_entries
  end

  def data
    partners.map do |partner|
      [
        partner.id,
        partner.prefix, 
        partner.name,
        partner.contract_uri,
        partner.website_url,
        (link_to(I18n.t(:show), @url_helpers.admin_partner_path(partner), :class => 'btn btn-mini')if @current_agent.can? :read, Partner)+
        (link_to(I18n.t(:dashboard), @url_helpers.admin_partner_dashboard_path(partner.prefix), :class => 'btn btn-mini')if @current_agent.can? :edit, Partner)+
        (link_to(I18n.t(:edit), @url_helpers.edit_admin_partner_path(partner), :class => 'btn btn-mini' )if @current_agent.can? :see_dashboard, Partner)      ]
    end
  end

  def partners
    @partners ||= fetch_partners
  end

  def fetch_partners
    partners = Partner.order("#{sort_column} #{sort_direction}")
    partners = partners.page(page).per_page(per_page)
    if params[:sSearch].present?
      partners = partners.where("prefix like :search or name like :search", search: "%#{params[:sSearch]}%")
    end
    partners
  end

  def sort_column
    Partner.datatable_columns[params[:iSortCol_0].to_i]
  end
end    