class FulfillmentsController < ApplicationController
  before_filter :validate_club_presence

  def index
    respond_to do |format|
      format.html 
      format.js 
    end
  end

  def report
  	if params[:all_times] == '1'
  		@fulfillments = Fulfillment.joins(:member).where('fulfillments.status like ? and club_id = ?', params[:status],@current_club.id)

  	end
    respond_to do |format|
      format.html {render 'index'}
      format.js {render 'index'}
    end
  end

  def set_as_not_processed
  	fulfillment = Fulfillment.find(params[:fulfillment_id])
  	product = Product.find_by_sku_and_club_id(fulfillment.product,@current_club)
  	fulfillment.set_as_not_processed
  	product.stock = product.stock-1	
  	product.save

  	respond_to do |format|
      format.html {render 'index'}
      format.js {render 'index'}
    end
  end
end