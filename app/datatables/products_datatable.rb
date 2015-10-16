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
        product.stock,
        product.allow_backorder ? 'Yes' : 'No',
        (link_to(I18n.t(:show), @url_helpers.product_path(@current_partner.prefix, @current_club.name, product.id), :class => 'btn btn-mini', :id => 'show') if @current_agent.can? :read, Product, @current_club.id).to_s+
        ((link_to(I18n.t(:edit), @url_helpers.edit_product_path(@current_partner.prefix, @current_club.name, product.id), :class => 'btn btn-mini', :id => 'edit', 'data-toggle' => 'custom-remote-modal', 'data-target' => product.id.to_s) + edit_modal(product)) if @current_agent.can? :edit, Product, @current_club.id).to_s+
        (link_to(I18n.t(:destroy), @url_helpers.product_path(@current_partner.prefix, @current_club.name, product.id), :method => :delete,
                :confirm => I18n.t("are_you_sure"), :id => 'destroy',
                :class => 'btn btn-mini btn-danger')if @current_agent.can? :delete, Product, @current_club.id).to_s
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

  def edit_modal(product)
    "<div id='myModal#{product.id}' class='well modal hide' style='border: none;'>
      <div class='modal-header'>
        <a href='#' class='close' data-dismiss='modal'>&times;</a>
        <h3>Edit Product ID #{product.id} - #{product.name}</h3>
      </div>
      <div class='modal-body'></div>
      <div class='modal-footer'>
        <input class='btn btn-primary' type='submit' value='Update Product' name='commit' data-target='#{product.id.to_s}'>
        <a href='#' class='btn' data-dismiss='modal' >Close</a>
      </div>
    </div>".html_safe
  end
end