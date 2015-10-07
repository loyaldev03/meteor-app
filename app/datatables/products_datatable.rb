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
        (link_to(I18n.t(:show), @url_helpers.product_path(@current_partner.prefix, @current_club.name, product.id), :class => 'btn btn-mini', :id => 'show') if @current_agent.can? :read, Product, @current_club.id).to_s+
        ((link_to(I18n.t(:edit), "#myModal_#{product.id}", :class => 'btn btn-mini', :id => 'edit', 'data-toggle' => 'modal') + edit_modal(product)) if @current_agent.can? :edit, Product, @current_club.id).to_s+
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
    "<div id='myModal_#{product.id}' class='well modal hide' style='border: none;'>
      <h3> Product ID #{product.id} - #{product.name} </h3>
      <hr>
      <form id='edit_product_#{product.id}' class='form-horizontal' method='put' action='#{@url_helpers.}' accept-charset='UTF-8'>
        <div class='control-group'>
          <label class='control-label required_asterisk' for='product_name'>Name</label>
          <div class='controls'>
            <input id='product_name' class='text_field' type='text' value='#{product.sku}' size='30' name='product[name]''>
          </div>
        </div>
      </form>
    </div>".html_safe
  end
end    