class FulfillmentsController < ApplicationController
  before_filter :validate_club_presence


  def index
    if request.post?
    	if params[:all_times] == '1'
    		@fulfillments = Fulfillment.joins(:member).where('fulfillments.status = ? and club_id = ?', params[:status], @current_club.id)
        @status = params[:status]
      elsif params[:status] == 'not_processed'
        fulfillments = Fulfillment.where(['status = ? AND date(assigned_at) BETWEEN ? and ? AND club_id = ?', 
            'not_processed', params[:initial_date], params[:end_date], @current_club.id])
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