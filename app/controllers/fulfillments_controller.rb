class FulfillmentsController < ApplicationController
  require 'csv'
  before_filter :validate_club_presence


  def index
    if request.post?
    	if params[:all_times] == '1'
    		@fulfillments = Fulfillment.joins(:member).where('fulfillments.status like ? and club_id = ?', params[:status],@current_club.id)
      elsif params[:status] == 'not_processed'
        fulfillments = Fulfillment.where(['status like ? AND assigned_at BETWEEN ? and ?', 'not_processed', params[:initial_date], params[:end_date]])
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
    flash[:error] = "Could not found the fulfillment."
    render 'index'
  end

  def mark_as_sent
    render json: Fulfillment.find(params[:id]).mark_as_sent(@current_agent)
  rescue ActiveRecord::RecordNotFound
    flash[:error] = "Could not found the fulfillment."
    render 'index'
  end

  def mark_as_wrong_address
    member = Member.find(Fulfillment.find(params[:id]).member_id)
    render json: member.set_wrong_address(@current_agent, params[:reason])
  rescue ActiveRecord::RecordNotFound
    flash[:error] = "Could not found the fulfillment."
    render 'index'
  end
end