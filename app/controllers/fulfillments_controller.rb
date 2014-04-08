class FulfillmentsController < ApplicationController
  before_filter :validate_club_presence

  def index
    my_authorize! :report, Fulfillment, @current_club.id
    if request.post?
      @status = params[:status]
    	if params[:all_times] == '1'
        if params[:product_type] == Settings.others_product
          @fulfillments = Fulfillment.includes(:member).joins(:member).where('fulfillments.status = ? and club_id = ?', params[:status], @current_club.id).type_others.not_renewed
        else
          @fulfillments = Fulfillment.includes(:member).joins(:member).where('fulfillments.status = ? and club_id = ? and product_sku = ? ', params[:status], @current_club.id, params[:product_type]).not_renewed
        end
        @product_type = params[:product_type]
      else
        if params[:product_type] == Settings.others_product
          @fulfillments = Fulfillment.includes(:member).joins(:member).where(['fulfillments.status = ? AND date(assigned_at) BETWEEN ? and ? AND club_id = ? ', 
            params[:status], params[:initial_date], params[:end_date], @current_club.id]).type_others.not_renewed
        else
          @fulfillments = Fulfillment.includes(:member).joins(:member).where(['fulfillments.status = ? AND date(assigned_at) BETWEEN ? and ? AND club_id = ? AND product_sku = ? ', 
            params[:status], params[:initial_date], params[:end_date], @current_club.id, params[:product_type]]).not_renewed
        end
      end  
    end
    params[:product_type] = params[:product_type] || Settings.kit_card_product
  end

  def files
    my_authorize! :report, Fulfillment, @current_club.id
    respond_to do |format|
      format.html
      format.json { render json: FulfillmentFilesDatatable.new(view_context,@current_partner,@current_club,@current_member,@current_agent)}
    end
  end

  def update_status
    my_authorize! :update_status, Fulfillment, @current_club.id
    fulfillment = Fulfillment.find(params[:id])
    file = (params[:file].blank? ? nil : params[:file])
    render json: fulfillment.update_status(@current_agent, params[:new_status], params[:reason], file).merge(:id => params[:id])
  rescue ActiveRecord::RecordNotFound => e
    render json: { :message => "Could not found the fulfillment.", :code => Settings.error_codes.not_found, :id => params[:id] }
  end

  # def resend
  #   my_authorize! :resend, Fulfillment, @current_club.id
  #   render json: Fulfillment.find(params[:id]).resend(@current_agent)
  # rescue ActiveRecord::RecordNotFound
  #   render json: { :message => "Could not found the fulfillment.", :code => Settings.error_codes.not_found }
  # end

  def list_for_file
    @file = FulfillmentFile.find(params[:fulfillment_file_id])
    @fulfillments = @file.fulfillments.includes(:member)
    render :index
  end

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
    if not params[:fulfillment_selected].nil?
      ff.save!
      ff.process_fulfillments_for_file(params[:fulfillment_selected])
      answer = { :code => Settings.error_codes.success, :fulfillment_file_id => ff.id, :message => "Fulfillment File is being generated. Please, wait until we are finished. It may take a while." }
    else
      answer = { :code => Settings.error_codes.wrong_data, :message => t('error_messages.fulfillment_file_cant_be_empty') }
    end
  else  
    render json: answer
  end

  def check_if_fulfillment_file_was_generated
    my_authorize! :report, Fulfillment, @current_club.id
    fulfillment_file = FulfillmentFile.find(params[:fulfillment_file_id].to_i)
    if fulfillment_file.fulfillments.count == params[:fulfillment_selected].count
      answer = { code: Settings.error_codes.success, :message => "File created succesfully. <a href='#{download_xls_fulfillments_path(:fulfillment_file_id => fulfillment_file.id)}' class='btn btn-success'>Download it from here</a>".html_safe }
    else
      answer = { code: Settings.error_codes.fulfillment_file_not_finished_yet, :message => "Processed #{fulfillment_file.fulfillments.count} out of #{params[:fulfillment_selected].count}." }
    end
    render json: answer
  end

  def download_xls
    my_authorize! :report, Fulfillment, @current_club.id
    fulfillment_file = FulfillmentFile.find(params[:fulfillment_file_id])
    fulfillment_file.send_email_with_file(params[:only_in_progress])

    flash[:notice] = "We are generating the Fulfillment File requested, and it will be delivered to your configured email as soon as it is ready. Have in mind this could take up to 15 minutes depending on the amount of members and fulfillments involved."

    redirect_to list_fulfillment_files_path
  end

  def mark_file_as_sent
    my_authorize! :report, Fulfillment, @current_club.id
    file = FulfillmentFile.find(params[:fulfillment_file_id])
    unless file.sent?
      file.processed!
      flash[:notice] = "Fulfillment file marked as sent successfully."
    else
      flash[:notice] = "Fulfillment file was already marked as sent."
    end
  rescue
    flash[:error] = t('error_messages.airbrake_error_message')
    Auditory.report_issue("FulfillmentFile:mark_file_as_sent", $!, { :file => file.inspect })
  ensure
    redirect_to list_fulfillment_files_path
  end

end