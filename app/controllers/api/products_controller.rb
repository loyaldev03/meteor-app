class Api::ProductsController < ApplicationController
  skip_before_filter :verify_authenticity_token
  respond_to :json
  
  ##
  # Returns the stock available for a product. 
  #
  # @resource /api/v1/products/get_stock
  # @action POST
  #
  # @required [String] api_key Agent's authentication token. This token allows us to check if the agent is allowed to request this action.
  # @required [String] sku Sku of the product we are interested in. This parameter is the product description. 
  # @required [String] club_id Id of the club the product belongs to. 
  # @response_field [Integer] stock Actual stock of the product. This value is an integer type. This value is returned if there was no error.
  # @response_field [Integer] allow_backorder Flag to inform that product allow negative stocks. It returns 1 for true value, and 0 for false value. This flag is returned if there was no error.  
  # @response_field [String] code Code related to the method result.
  # @response_field [String] message Shows the method errors.
  # 
  # @example_request
  #   curl -v -k -X POST -d "api_key=zmemqz1Yi6v6aEm5fLjt&club_id=2&sku=KIT-CARD" https://dev.stoneacrehq.com:3000/api/v1/products/get_stock
  # @example_request_description Example of valid request. 
  #
  # @example_response
  #   {"code":"000","stock":9746,"allow_backorder":true}
  # @example_response_description Example response to valid request.
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

  ##
  # Returns the stock available and the backorder flag for a list of product. 
  #
  # @resource /api/v1/products/get_list_of_stock
  # @action POST
  #
  # @required [String] api_key Agent's authentication token. This token allows us to check if the agent is allowed to request this action.
  # @required [String] sku product's skus that we are interest in. Skus must be separated by commas. (Eg: "KIT-CARD,NCARFLAGKASEYKAHNE")
  # @required [String] club_id Id of the club the products belongs to. 
  # @response_field [Array] product_list Array of Hashes with the product's information. This Array is returned if there were no error.
  # <ul>
  #   <li><strong>sku</strong> Product's sku. </li>
  #   <li><strong>stock</strong> Actual stock of the product. This value is an integer type </li>
  #   <li><strong>allow_backorder</strong> Flag to inform that product allow negative stocks. It returns 1 for true value, and 0 for false value. </li>
  # </ul>
  # @response_field [Array] skus_could_not_found Array with the skus that we were not able to find. 
  # @response_field [String] code Code related to the method result.
  # @response_field [String] message Shows the method errors.
  # 
  # @example_request
  #   curl -v -k -X POST -d "api_key=zmemqz1Yi6v6aEm5fLjt&club_id=2&sku=KIT-CARD,AnoterOne,NCARFLAGTONYSTEWART" https://dev.stoneacrehq.com:3000/api/v1/products/get_list_of_stock
  # @example_request_description Example of valid request. 
  #
  # @example_response
  #   {"code":"000","product_list":[{"sku":"KIT-CARD","stock":9746,"allow_backorder":true}],"skus_could_not_found":["AnoterOne","NCARFLAGTONYSTEWART"]}
  # @example_response_description Example response to valid request.
  #
  def get_list_of_stock
    my_authorize! :manage_product_api, Product, params[:club_id]
    skus = params[:sku].to_s.split(',')
    if skus.count == 0 or params[:club_id].blank?
      response = { code: Settings.error_codes.wrong_data, message: 'Please check params, There seems to be some missing.' }
    else
      skus_could_not_found = []
      product_list = []
      skus.each do |sku|
        product = Product.find_by_sku_and_club_id(sku, params[:club_id])
        if product.nil?
          skus_could_not_found << sku    
        else
          product_list << { sku: product.sku, stock: product.stock, allow_backorder: product.allow_backorder }
        end
      end
      response = { code: Settings.error_codes.success, product_list: product_list, skus_could_not_found: skus_could_not_found }
    end
    render json: response
  end
end
