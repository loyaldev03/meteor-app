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
        link_to(partner.id, "partners/#{partner.id}"),
        partner.prefix, 
        partner.name,
        partner.contract_uri,
        partner.website_url,
        partner.description,
        I18n.l(partner.created_at,:format=>:long),
        [link_to(I18n.t(:dashboard), "/partner/#{partner.prefix}/dashboard", :class => 'btn btn-mini'),
         link_to(I18n.t(:edit), "partners/#{partner.id}/edit", :class => 'btn btn-mini' ),
         link_to(I18n.t(:destroy), "partners/#{partner.id}", :method => :delete,
                        :confirm => I18n.t('.confirm', :default => I18n.t("helpers.links.confirm", :default => 'Are you sure?')),
                        :class => 'btn btn-mini btn-danger')]
      ]
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
    columns = ['id', 'prefix', 'name', 'contract_uri', 'website_url', 'description', 'created_at']
    columns[params[:iSortCol_0].to_i]
  end
end    