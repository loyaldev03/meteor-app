class FulfillmentsController < ApplicationController
  require 'csv'
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
  	  render 'index'
    elsif params[:status] == 'not_processed'
      fulfillments = Fulfillment.where(['status like ? AND assigned_at BETWEEN ? and ?', 'not_processed', params[:initial_date], params[:end_date]])
      row = []
      csv_string = CSV.generate do |csv| 
        csv << ['PackageId', 'Costcenter', 'Companyname', 'Address', 'City', 'State', 'Zip', 'Endorsement', 
              'Packagetype', 'Divconf', 'Bill Transportation', 'Weight', 'UPS Service']
        fulfillments.each do |fulfillment|
        member = Member.find(fulfillment.member_id)
        product = Product.find_by_sku_and_club_id(fulfillment.product,member.club_id)
        if product.stock > 0
          row << fulfillment.tracking_code
          row << 'Costcenter'
          row << member.full_name
          row << member.address
          row << member.city
          row << member.state
          row << member.zip
          row << 'Return Service Requested'
          row << 'Irregulars'
          row << 'Y'
          row << 'Shipper'
          row << product.weight
          row << 'MID'
          csv << row
          row = []
          fulfillment.set_as_processing
          product.decrease_stock(1)
        end
      end
      csv << row
    end
    send_data csv_string, :filename => "export.csv",
                   :type => 'text/csv; charset=iso-8859-1; header=present',
                   :disposition => "attachment; filename=export.csv"
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
    end
  end

  def mark_as_sent
    fulfillment = Fulfillment.find(params[:fulfillment_id])
    if fulfillment.set_as_sent
      message = "Fulfillment #{fulfillment.product} was set as sent."
      Auditory.audit(@current_agent, fulfillment, message, Member.find(fulfillment.member_id), Settings.operation_types.fulfillment_mannualy_mark_as_sent)
      flash[:notice] = message
    else
      flash[:error] = "Could not mark as sent."
    end
    respond_to do |format|
      format.html {render 'index'}
    end    
  end

  def mark_as_wrong_address
    member = Member.find(Fulfillment.find(params[:fulfillment_id]).member_id)
    answer = member.set_wrong_address(@current_agent, params[:reason])
    if answer[:success]
      flash[:notice] = answer[:message]
    else
      flash[:error] = answer[:message]
    end

    respond_to do |format|
      format.html {render 'index'}
    end     
  end

  def generate_csv
    fulfillments = Fulfillment.where(['status like ? AND assigned_at BETWEEN ? and ?', 'not_processed', params[:initial_date], params[:end_date]])

  end 
end