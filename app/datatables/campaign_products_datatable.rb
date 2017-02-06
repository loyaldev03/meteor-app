class CampaignProductsDatatable < Datatable
  attr_accessor :campaign

  private

  def total_records
    campaign.products.count
  end

  def total_entries
    products.total_entries
  end

  def data
    products.map do |product|
      [
        product.name,
        product.sku,
        landing_label(product),
        product.stock,
        (
          (link_to(I18n.t(:rename), '#', id: 'btn-edit-label', class: 'btn btn-mini', data: { target: @url_helpers.campaign_products_edit_label_path(@current_partner.prefix, @current_club.name, product_id: product.id, campaign_id: campaign.id), toggle: 'custom-remote-modal', label: product.name }) if @current_agent.can? :edit, Campaign, @current_club.id).to_s +
          (link_to I18n.t(:remove), 'javascript:;', id: 'btn-remove-product', class: 'btn btn-mini btn-danger', data: { product_id: product.id, campaign_id: campaign.id }).to_s
        )
      ]
    end
  end

  def products
    @assigned_products ||= fetch_products
  end

  def fetch_products
    products = campaign.products.where(club_id: @current_club.id).order("#{sort_column} #{sort_direction}")
    products = products.page(page).per_page(per_page)
    if params[:sSearch].present?
      products = products.where('sku LIKE :search OR name LIKE :search', search: "%#{params[:sSearch]}%")
    end
    products
  end

  def sort_column
    cols = ['name', 'sku', nil, 'stock']
    cols[params[:iSortCol_0].to_i]
  end

  def landing_label(product)
    CampaignProduct.find_by(campaign_id: campaign.id, product_id: product.id).label
  end
end
