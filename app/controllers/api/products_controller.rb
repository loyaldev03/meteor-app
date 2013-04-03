class Api::ProductsController < ApplicationController
  skip_before_filter :verify_authenticity_token
  respond_to :json
  
  ##
  # Returns the stock available for a product. 
  #
  # @resource /api/v1/products/get_stock
  # @action GET
  #
  # @required [String] api_key Agent's authentication token. This token allows us to check if the agent is allowed to request this action. This token is obtained using token's POST api method. <a href="TokensController.html">TokensMethods</a>
  # @required [String] sku Sku of the product we are interested in. This parameter is the product description. 
  # @required [String] club_id Id of the club the product belongs to. 
  # @response_field [Integer] stock Actual stock of the product. This value is an integer type. This value is returned if there was no error.
  # @response_field [Integer] allow_backorder Flag to inform that product allow negative stocks. It returns 1 for true value, and 0 for false value. This flag is returned if there was no error.  
  # @response_field [Integer] code Code related to the method result.
  # @response_field [String] message Shows the method errors.
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
