class ProductsDatatable < Datatable
private

  def total_records
    Product.where(club_id: @current_club.id).count
  end

  def total_entries
    products.total_entries
  end

  def data
    products.map do |product|
      [
        product.id,
        product.name,
        product.sku,
        product.stock.to_s,
        product.allow_backorder ? 'Yes' : 'No',
        (link_to(I18n.t(:show), @url_helpers.product_path(@current_partner.prefix, @current_club.name, product.id), :class => 'btn btn-mini', :id => 'show') if @current_agent.can? :read, Product, @current_club.id).to_s +
        (link_to(I18n.t(:import_data), @url_helpers.store_products_import_path(@current_partner.prefix, @current_club.name), class: 'btn btn-mini', data: {product: product.id, action: 'import_product_data'}) if(@current_club.has_store_configured? and @current_agent.can?(:read, Product, @current_club.id))).to_s +
        (link_to(I18n.t(:link_to_store_variant), product.store_variant_url, class: 'btn btn-mini', target:'_blank') if(@current_club.has_store_configured? and @current_agent.can?(:read, Product, @current_club.id))).to_s 
      ]
    end
  end

  def products
    @products ||= fetch_products
  end

  def fetch_products
    products = Product.where(:club_id => @current_club.id).order("#{sort_column} #{sort_direction}")
    products = products.page(page).per_page(per_page)
    if params[:sSearch].present?
      products = products.where("id like :search or name like :search or sku like :search", search: "%#{params[:sSearch]}%")
    end
    products
  end

  def sort_column
    Product.datatable_columns[params[:iSortCol_0].to_i]
  end
end
