class CampaignProductsAvailableDatatable < Datatable
  attr_accessor :campaign

  private

  def total_records
    Product.where(club_id: @current_club.id).where.not(id: campaign.products.pluck(:id)).count
  end

  def total_entries
    products.total_entries
  end

  def data
    products.map do |product|
      [
        product.name,
        product.sku,
        product.stock,
        product.image_url.present? ? 'Yes' : 'No',
        (product.can_be_assigned_to_campaign? ? link_to(I18n.t('assign'), 'javascript:;', id: 'btn-assign-product', class: 'btn btn-mini btn-primary', data: { product_id: product.id, campaign_id: campaign.id }) : '(*)')
      ]
    end
  end

  def products
    @available_products ||= fetch_products
  end

  def fetch_products
    products = Product.where(club_id: @current_club.id).where.not(id: campaign.products.pluck(:id)).order("#{sort_column} #{sort_direction}")
    products = products.page(page).per_page(per_page)
    if params[:sSearch].present?
      products = products.where('sku LIKE :search OR name LIKE :search', search: "%#{params[:sSearch]}%")
    end
    products
  end

  def sort_column
    cols = %w(name sku stock image_url)
    cols[params[:iSortCol_0].to_i]
  end
end
