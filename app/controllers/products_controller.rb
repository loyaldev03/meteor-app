class ProductsController < ApplicationController
  before_filter :validate_club_presence
  before_filter :check_permissions

  # GET /products
  # GET /products.json
  def index
    my_authorize! :list, Product, @current_club.id
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: ProductsDatatable.new(view_context,@current_partner,@current_club,nil,@current_agent) }
    end
  end

  # GET /products/1
  def show
    @product = Product.find(params[:id])
    my_authorize! :show, Product, @product.club_id
  end

  # GET /products/new
  def new
    my_authorize! :new, Product, @current_club.id
    @product = Product.new
  end

  # GET /products/1/edit
  def edit
    @product = Product.find(params[:id])
    my_authorize! :edit, Product, @product.club_id
    render partial: "edit"
  end

  # POST /products
  def create
    my_authorize! :create, Product, @current_club.id
    @product = Product.new(product_params)
    @product.club_id = @current_club.id
    if @product.save
      redirect_to product_path(@current_partner.prefix,@current_club.name, @product), notice: 'Product was successfully created.'
    else
      render action: "new"
    end
  rescue ActiveRecord::RecordNotUnique => e
    flash.now[:error] = "Product with sku '#{@product.sku}' already exists within this club."
    render action: "new"
  end

  # PUT /products/1
  def update
    @product = Product.find(params[:id])
    my_authorize! :update, Product, @product.club_id
    if @product.update product_params
      render json: { success: true }
    else
      render json: { success: false, message: 'Product was not updated.', errors: @product.errors }
    end
  rescue ActiveRecord::RecordNotUnique => e
    render json: { success: false, message: "Sku '#{@product.sku}' is already taken within this club." }
  end

  def bulk_process
    my_authorize! :bulk_process, Product, current_club.id
    if request.post?
      if params[:bulk_process_file]
        if ['text/csv','application/vnd.ms-excel'].include? params[:bulk_process_file].content_type
          temporary_file = File.open("tmp/files/bulk_process_#{Time.current}.csv", "w")
          temporary_file.write params[:bulk_process_file].open.read
          temporary_file.close
          temporary_file
          Product.delay.bulk_process(@current_club.id, current_agent.email, temporary_file.path)
          redirect_to products_url, notice: "File will be processed in a few moments. We will send you the results to your email."
        else 
          redirect_to bulk_process_products_url, alert: "Format not supported. Please, provide a .csv file"
        end
      else 
        redirect_to bulk_process_products_url, alert: "No file provided."
      end
    end
  end

  # DELETE /products/1
  def destroy
    @product = Product.find(params[:id])
    my_authorize! :destroy, Product, @product.club_id
    if @product.destroy
      redirect_to products_url, notice: "Product #{@product.sku} was successfully destroyed."
    else
      flash[:error] = "Product #{@product.sku} was not destroyed."
      redirect_to products_url
    end
  end

  private
    def product_params
      params.require(:product).permit(:sku, :name, :package, :recurrent, :stock, :alert_on_low_stock, :weight, :allow_backorder, :is_visible, :cost_center, :image_url)
    end

    def check_permissions
      my_authorize! :manage, Product, @current_club.id
    end
end
