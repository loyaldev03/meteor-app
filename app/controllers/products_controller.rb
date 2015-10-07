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
  end

  # POST /products
  def create
    my_authorize! :create, Product, @current_club.id
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
    require "ruby-debug"; debugger
    @product = Product.find(params[:id])
    my_authorize! :update, Product, @product.club_id
    @product.update_product_data_by_params params[:product]
    if @product.save
      render json: { success: true }
    else
      render json: { success: false, message: 'Product was not updated.' }
    end
  rescue ActiveRecord::RecordNotUnique => e
    render json: { success: false, message: "Sku '#{@product.sku}' is already taken within this club." }
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

    def check_permissions
      my_authorize! :manage, Product, @current_club.id
    end

end
