class ProductsController < ApplicationController
  before_filter :check_permissions
  before_filter :validate_club_presence

  # GET /products
  # GET /products.json
  def index
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: ProductsDatatable.new(view_context,@current_partner,@current_club) }
    end
  end

  # GET /products/1
  # GET /products/1.json
  def show
    @product = Product.find(params[:id])
  end

  # GET /products/new
  # GET /products/new.json
  def new
    @product = Product.new
  end

  # GET /products/1/edit
  def edit
    @product = Product.find(params[:id])
  end

  # POST /products
  # POST /products.json
  def create
    @product = Product.new(params[:product])
    @product.club_id = @current_club.id
    if @product.save
      redirect_to product_path(@current_partner.prefix,@current_club.name, @product), notice: 'Product was successfully created.'
    else
      render action: "new"
    end
  end

  # PUT /products/1
  # PUT /products/1.json
  def update
    @product = Product.find(params[:id])

    if @product.update_attributes(params[:product])
      redirect_to product_path(@current_partner.prefix,@current_club.name, @product), notice: 'Product was successfully created.' 
    else
      render action: "edit"
    end
  end

  # DELETE /products/1
  # DELETE /products/1.json
  def destroy
    @product = Product.find(params[:id])
    @product.destroy
    redirect_to products_url 
  end

  def check_permissions
    authorize! :manage, Product.new     
  end


end
