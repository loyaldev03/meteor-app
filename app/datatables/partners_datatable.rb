class PartnersDatatable
  delegate :params, :h, :link_to, :number_to_currency, to: :@view

  def initialize(view)
    @view = view
  end

  def as_json(options = {})
    {
      sEcho: params[:sEcho].to_i,
      iTotalRecords: Partner.count,
      iTotalDisplayRecords: partners.total_entries,
      aaData: data
    }
  end

private

  def data
    partners.map do |partner|
      [
        link_to(partner.id, "/partner/#{partner.id}"),
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

  def page
    params[:iDisplayStart].to_i/per_page + 1
  end

  def per_page
    params[:iDisplayLength].to_i > 0 ? params[:iDisplayLength].to_i : 10
  end

  def sort_column
    columns = ['id', 'prefix', 'name', 'contract_uri', 'website_url', 'description', 'created_at']
    columns[params[:iSortCol_0].to_i]
  end

  def sort_direction
    params[:sSortDir_0] == "desc" ? "desc" : "asc"
  end
end    