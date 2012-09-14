class FulfillmentsController < ApplicationController
  before_filter :validate_club_presence

  def index
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
      elsif params[:status] == 'not_processed'
        if params[:product_type] == 'KIT'
          fulfillments = Fulfillment.joins(:member).where(['fulfillments.status = ? AND date(assigned_at) BETWEEN ? and ? AND club_id = ?', 
            'not_processed', params[:initial_date], params[:end_date], @current_club.id]).type_kit
        elsif params[:product_type] == 'CARD'        
          fulfillments = Fulfillment.joins(:member).where(['fulfillments.status = ? AND date(assigned_at) BETWEEN ? and ? AND club_id = ?', 
            'not_processed', params[:initial_date], params[:end_date], @current_club.id]).type_card
        else
          fulfillments = Fulfillment.joins(:member).where(['fulfillments.status = ? AND date(assigned_at) BETWEEN ? and ? AND club_id = ?', 
            'not_processed', params[:initial_date], params[:end_date], @current_club.id]).type_others
        end
        csv_string = Fulfillment.generateCSV(fulfillments)
        send_data csv_string, :filename => "miworkingfile2.csv",
                     :type => 'text/csv; charset=iso-8859-1; header=present',
                     :disposition => "attachment; filename=miworkingfile2.csv"
      end  
    end
  end

  def resend
    render json: Fulfillment.find(params[:id]).resend(@current_agent)
  rescue ActiveRecord::RecordNotFound
    render json: { :message => "Could not found the fulfillment.", :code => Settings.error_codes.not_found }
  end

  def mark_as_sent
    render json: Fulfillment.find(params[:id]).mark_as_sent(@current_agent)
  rescue ActiveRecord::RecordNotFound
    render json: { :message => "Could not found the fulfillment.", :code => Settings.error_codes.not_found }
  end

  def mark_as_wrong_address
    render json: Fulfillment.find(params[:id]).member.set_wrong_address(@current_agent, params[:reason])
  rescue ActiveRecord::RecordNotFound
    render json: { :message => "Could not found the fulfillment.", :code => Settings.error_codes.not_found }
  end

  def generate_csv
    fulfillments = Fulfillment.joins(:member).where('fulfillments.status = ? and club_id = ?', params[:status],@current_club.id)
    csv_string = Fulfillment.generateCSV(fulfillments)
    send_data csv_string, :filename => "miworkingfile2.csv",
                 :type => 'text/csv; charset=iso-8859-1; header=present',
                 :disposition => "attachment; filename=miworkingfile2.csv"
  end
end