class ProductsDatatable < Datatable
private

  def total_records
    Product.find_all_by_club_id(@current_club.id).count
  end

  def total_entries
    products.total_entries
  end

  def data
    products.map do |product|
      [
        product.id,
        product.name,
        product.recurrent,
        product.stock,
        product.weight,
        link_to(I18n.t(:show), @url_helpers.product_path(@current_partner.prefix, @current_club.name, product.id), :class => 'btn btn-mini')+
        link_to(I18n.t(:edit), @url_helpers.edit_product_path(@current_partner.prefix, @current_club.name, product.id), :class => 'btn btn-mini')+
        link_to(I18n.t(:destroy), @url_helpers.product_path(@current_partner.prefix, @current_club.name, product.id), :method => :delete,
                :confirm => I18n.t("are_you_sure"),
                :class => 'btn btn-mini btn-danger')
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
      products = products.where("id like :search or name like :search", search: "%#{params[:sSearch]}%")
    end
    products
  end

  def sort_column
    Product.datatable_columns[params[:iSortCol_0].to_i]
  end
end    