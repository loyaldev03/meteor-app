class ProductsController < ApplicationController
  before_filter :validate_club_presence
  before_filter :check_permissions

  # GET /products
  # GET /products.json
  def index
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: ProductsDatatable.new(view_context,@current_partner,@current_club,nil,@current_agent) }
    end
  end

  # GET /products/1
  def show
    @product = Product.find(params[:id])
  end

  # GET /products/new
  def new
    @product = Product.new
  end

  # GET /products/1/edit
  def edit
    @product = Product.find(params[:id])
  end

  # POST /products
  def create
    @product = Product.new
    @product.club_id = @current_club.id
    @product.update_product_data_by_params(params[:product])
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
    @product.update_product_data_by_params params[:product]
    if @product.save
      redirect_to product_path(@current_partner.prefix,@current_club.name, @product), notice: 'Product was successfully updated.' 
    else
      render action: "edit"
    end
  rescue ActiveRecord::RecordNotUnique => e
    flash.now[:error] = "Sku '#{@product.sku}' is already taken within this club."
    render action: "edit"  
  end

  # DELETE /products/1
  def destroy
    @product = Product.find(params[:id])
    if @product.destroy
      redirect_to products_url, notice: "Product #{@product.sku} was successfully destroyed."
    else
      flash[:error] = "Product #{@product.sku} was not destroyed."
      redirect_to products_url
    end
  end

  private

    def check_permissions
      my_authorize! :manage, Product, @current_club.id
    end

end
