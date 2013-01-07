class FulfillmentsController < ApplicationController
  before_filter :validate_club_presence

  def index
    my_authorize! :report, Fulfillment, @current_club.id
    if request.post?
    	if params[:all_times] == '1'
        if params[:product_type] == 'KIT'
    		  @fulfillments = Fulfillment.joins(:member).where('fulfillments.status = ? and club_id = ?', params[:status], @current_club.id).type_kit
        elsif params[:product_type] == 'CARD'
          @fulfillments = Fulfillment.joins(:member).where('fulfillments.status = ? and club_id = ?', params[:status], @current_club.id).type_card
        else
          @fulfillments = Fulfillment.joins(:member).where('fulfillments.status = ? and club_id = ?', params[:status], @current_club.id).type_others
        end
        @status = params[:status]
        @product_type = params[:product_type]
      elsif params[:status] == 'not_processed'
        if params[:product_type] == 'KIT'
          fulfillments = Fulfillment.joins(:member).where(['fulfillments.status = ? AND date(assigned_at) BETWEEN ? and ? AND club_id = ? AND renewed = false', 
            'not_processed', params[:initial_date], params[:end_date], @current_club.id]).type_kit
        elsif params[:product_type] == 'CARD'        
          fulfillments = Fulfillment.joins(:member).where(['fulfillments.status = ? AND date(assigned_at) BETWEEN ? and ? AND club_id = ? AND renewed = false', 
            'not_processed', params[:initial_date], params[:end_date], @current_club.id]).type_card
        else
          fulfillments = Fulfillment.joins(:member).where(['fulfillments.status = ? AND date(assigned_at) BETWEEN ? and ? AND club_id = ? AND renewed = false', 
            'not_processed', params[:initial_date], params[:end_date], @current_club.id]).type_others
        end

        if params[:product_type] == 'KIT' or params[:product_type] == 'CARD' 
          xls_package = Fulfillment.generateXLS(fulfillments, false, false)
        else
          xls_package = Fulfillment.generateXLS(fulfillments, false)
        end

        send_data xls_package.to_stream.read, :filename => "miworkingfile2.xlsx",
                 :type => "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                 :disposition => "attachment; filename=miworkingfile2.xlsx"
      end  
    end
  end

  def resend
    my_authorize! :resend, Fulfillment, @current_club.id
    render json: Fulfillment.find(params[:id]).resend(@current_agent)
  rescue ActiveRecord::RecordNotFound
    render json: { :message => "Could not found the fulfillment.", :code => Settings.error_codes.not_found }
  end

  def mark_as_sent
    my_authorize! :mark_as_sent, Fulfillment, @current_club.id
    render json: Fulfillment.find(params[:id]).mark_as_sent(@current_agent)
  rescue ActiveRecord::RecordNotFound
    render json: { :message => "Could not found the fulfillment.", :code => Settings.error_codes.not_found }
  end

  def mark_as_wrong_address
    my_authorize! :mark_as_wrong_address, Fulfillment, @current_club.id
    render json: Fulfillment.find(params[:id]).member.set_wrong_address(@current_agent, params[:reason])
  rescue ActiveRecord::RecordNotFound
    render json: { :message => "Could not found the fulfillment.", :code => Settings.error_codes.not_found }
  end

  def generate_csv
    generate_file(:generateCSV)
  end

  def generate_xls
    generate_file(:generateXLS)
  end

  private
    # TODO: filter by period
    def generate_file(method)
      my_authorize! :report, Fulfillment, @current_club.id
      if params[:product_type] == 'KIT'
        fulfillments = Fulfillment.joins(:member).where('fulfillments.status = ? and club_id = ?', params[:status], @current_club.id).type_kit
      elsif params[:product_type] == 'CARD'
        fulfillments = Fulfillment.joins(:member).where('fulfillments.status = ? and club_id = ?', params[:status], @current_club.id).type_card
      elsif params[:product_type] == 'OTHERS'
        fulfillments = Fulfillment.joins(:member).where('fulfillments.status = ? and club_id = ?', params[:status], @current_club.id).type_others
      end

      if params[:product_type] == 'KIT' or params[:product_type] == 'CARD' 
        xls_package = Fulfillment.send(method, fulfillments, true, false)
      else
        xls_package = Fulfillment.send(method, fulfillments, true)
      end

      send_data xls_package.to_stream.read, :filename => "miworkingfile2.xlsx",
                   :type => "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                   :disposition => "attachment; filename=miworkingfile2.xlsx"    
    end


end