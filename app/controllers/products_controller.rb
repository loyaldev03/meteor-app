class ProductsController < ApplicationController
  before_filter :validate_club_presence
  before_filter :check_permissions

  # GET /products
  # GET /products.json
  def index
    my_authorize! :list, Product, @current_club.id
    flash.now[:alert] = "This club does not have any Store Transport Setting configured. Configure a new Store Transport Setting with a new or already created Store credentials" unless current_club.has_store_configured?
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

  private
    def check_permissions
      my_authorize! :manage, Product, @current_club.id
    end
end
