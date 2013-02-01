class Api::ProductsController < ApplicationController
  skip_before_filter :verify_authenticity_token

  respond_to :json

  # Method : GET
  # Returns the stock available for a product. 
  # 
  # [url] /api/v1/products/get_stock
  # [sku] Sku of the product we are interested in. This parameter is the product description. 
  # [club_id] Id of the club the product belongs to. 
  # [stock] Actual stock of the product. This value is an integer type.
  # [code] Code related to the method result.
  # [allow_backorder] Flag to inform that product allow negative stocks. 
  #
  # @param [String] *sku*
  # @param [String] *club_id* 
  # @return [Integer] *code*
  # @return [Integer] *stock*
  # @return [Boolean] *allow_backorder*
  #
  def get_stock
    my_authorize! :manage_product_api, Product, params[:club_id]
    product = Product.find_by_sku_and_club_id(params[:sku],params[:club_id])
    if product.nil?
      render json: { code: Settings.error_codes.not_found, message: 'Product not found' }
    else
      render json: { code: Settings.error_codes.success, stock: product.stock, allow_backorder: product.allow_backorder }
    end
  end

end
