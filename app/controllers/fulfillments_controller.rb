class FulfillmentsController < ApplicationController
  before_filter :validate_club_presence

  def index
    my_authorize! :report, Fulfillment, @current_club.id
    # TODO: remove canceeled
    @possible_status = Fulfillment.state_machines[:status].states.map(&:name)
    if request.post?

    	if params[:all_times] == '1'
        if params[:product_type] == 'KIT-CARD'
    		  @fulfillments = Fulfillment.joins(:member).where('fulfillments.status = ? and club_id = ?', params[:status], @current_club.id).type_kit_card
        else
          @fulfillments = Fulfillment.joins(:member).where('fulfillments.status = ? and club_id = ?', params[:status], @current_club.id).type_others
        end
        @status = params[:status]
        @product_type = params[:product_type]
      else
        if params[:product_type] == 'KIT-CARD'
          @fulfillments = Fulfillment.joins(:member).where(['fulfillments.status = ? AND date(assigned_at) BETWEEN ? and ? AND club_id = ? AND renewed = false', 
            params[:status], params[:initial_date], params[:end_date], @current_club.id]).type_kit_card
        else
          @fulfillments = Fulfillment.joins(:member).where(['fulfillments.status = ? AND date(assigned_at) BETWEEN ? and ? AND club_id = ? AND renewed = false', 
            params[:status], params[:initial_date], params[:end_date], @current_club.id]).type_others
        end

      end  
    end
  end

  def update_status
    my_authorize! :update_status, Fulfillment, @current_club.id
    render json: Fulfillment.find(params[:id]).update_status(@current_agent, params[:status], params[:reason])
  rescue ActiveRecord::RecordNotFound
    render json: { :message => "Could not found the fulfillment.", :code => Settings.error_codes.not_found }
  end

  # def resend
  #   my_authorize! :resend, Fulfillment, @current_club.id
  #   render json: Fulfillment.find(params[:id]).resend(@current_agent)
  # rescue ActiveRecord::RecordNotFound
  #   render json: { :message => "Could not found the fulfillment.", :code => Settings.error_codes.not_found }
  # end


  def generate_xls
    my_authorize! :report, Fulfillment, @current_club.id
    ff = FulfillmentFile.new   
    ff.agent = current_agent
    ff.club = @current_club
    if params[:all_times] == '1'
      ff.initial_date, ff.end_date, ff.all_times = nil, nil, true
    else
      ff.initial_date, ff.end_date, ff.all_times = params[:initial_date], params[:end_date], false
    end
    ff.product = params[:product_type]
    if ff.save
      params[:fulfillment_selected].each do |fs|
        fulfillment = Fulfillment.find(fs.first)
        ff.fulfillments << fulfillment
        fulfillment.set_as_processing
      end
      flash.now[:notice] = "File created succesfully. <a href='#{download_xls_fulfillments_path(:fulfillment_file_id => ff.id)}' class='btn btn-success'>Download it from here</a>".html_safe
    else
      flash.now[:error] = "Error while processing this fulfillment. Contact the administrator."
    end
    render :index
  end

  def download_xls
    my_authorize! :report, Fulfillment, @current_club.id
    fulfillments = FulfillmentFile.find(params[:fulfillment_file_id]).fulfillments
    xls_package = Fulfillment.generateXLS(fulfillments, false, fulfillments.product == 'OTHERS')
    send_data xls_package.to_stream.read, :filename => "miworkingfile2.xlsx",
             :type => "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
             :disposition => "attachment; filename=miworkingfile2.xlsx"
  end

end