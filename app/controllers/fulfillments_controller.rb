class FulfillmentsController < ApplicationController
  before_filter :validate_club_presence

  def index
    my_authorize! :report, Fulfillment, @current_club.id
    if request.post?
      @status = params[:status]
      if params[:all_times] == '1'     
        if params[:radio_product_filter].blank?
          @fulfillments = Fulfillment.includes(:user).joins(:user).where('fulfillments.status = ? and fulfillments.club_id = ?', params[:status], @current_club.id).not_renewed
        elsif params[:radio_product_filter] == 'sku'
          @fulfillments = Fulfillment.includes(:user).joins(:user).where('fulfillments.status = ? and fulfillments.club_id = ? and product_sku like ?', params[:status], @current_club.id, "%#{params[:product_filter]}%").not_renewed
        end
      else
        if params[:radio_product_filter].blank?
          @fulfillments = Fulfillment.includes(:user).joins(:user).where(['fulfillments.status = ? AND date(assigned_at) BETWEEN ? and ? AND fulfillments.club_id = ? ', 
            params[:status], params[:initial_date], params[:end_date], @current_club.id]).not_renewed
        elsif params[:radio_product_filter] == 'sku'
          @fulfillments = Fulfillment.includes(:user).joins(:user).where(['fulfillments.status = ? AND date(assigned_at) BETWEEN ? and ? AND fulfillments.club_id = ? AND product_sku like ? ', 
            params[:status], params[:initial_date], params[:end_date], @current_club.id, "%#{params[:product_filter]}%"]).not_renewed
        end
      end
      @product_filter = params[:product_filter]
    end
  end

  def files
    my_authorize! :report, Fulfillment, @current_club.id
    respond_to do |format|
      format.html
      format.json { render json: FulfillmentFilesDatatable.new(view_context,@current_partner,@current_club,@current_user,@current_agent)}
    end
  end

  def update_status
    fulfillment = Fulfillment.find(params[:id])
    my_authorize! :update_status, Fulfillment, fulfillment.club_id
    file = (params[:file].blank? ? nil : params[:file])

    render json: fulfillment.update_status(@current_agent, params[:new_status], params[:reason], file).merge(:id => params[:id])
  rescue ActiveRecord::RecordNotFound => e
    render json: { :message => "Could not found the fulfillment.", :code => Settings.error_codes.not_found, :id => params[:id] }
  rescue CanCan::AccessDenied
    render json: { :message => "You are not allowed to change status on this fulfillment.", :code => Settings.error_codes.not_authorized, :id => params[:id] }
  end

  def manual_review
    if ['not_processed', 'canceled', 'do_not_honor'].include? params[:new_status]  
      fulfillment = Fulfillment.find(params[:id])
      my_authorize! :manual_review, Fulfillment, fulfillment.club_id
      answer = fulfillment.update_status(@current_agent, params[:new_status])
      
      message = answer[:code] == Settings.error_codes.success ? { notice: answer[:message] } : { alert: answer[:message] }
      redirect_to show_user_path(user_prefix: fulfillment.user_id), message
    else  
      flash[:error] = "You are not allowed to update to that status."
      redirect_to my_clubs_path
    end
  rescue ActiveRecord::RecordNotFound => e
    flash[:error] = "Could not found the fulfillment."
    redirect_to my_clubs_path
  end

  # def resend
  #   my_authorize! :resend, Fulfillment, @current_club.id
  #   render json: Fulfillment.find(params[:id]).resend(@current_agent)
  # rescue ActiveRecord::RecordNotFound
  #   render json: { :message => "Could not found the fulfillment.", :code => Settings.error_codes.not_found }
  # end

  def list_for_file
    @file = FulfillmentFile.find(params[:fulfillment_file_id])
    my_authorize! :report, Fulfillment, @file.club_id
    @fulfillments = @file.fulfillments.includes(:user)
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
    ff.product = params[:product_filter].blank? ? Settings.others_product : params[:product_filter]
    if not params[:fulfillment_selected].nil?
      begin
        FulfillmentFile.transaction do 
          ff.save!
          ff_counts = 0
          params[:fulfillment_selected].each do |fs|
            fulfillment = Fulfillment.find(fs.first)
            if fulfillment.club_id == ff.club_id
              ff.fulfillments << fulfillment
              fulfillment.update_status(ff.agent, "in_process", "Fulfillment file generated", ff.id)
              ff_counts += 1
            end
          end
          ff.fulfillment_count = ff_counts
          ff.save
          if ff_counts == 0
            flash.now[:error] = t('error_messages.fulfillment_file_cant_be_empty') 
            raise ActiveRecord::Rollback
          else
            flash.now[:notice] = "File created succesfully. <a href='#{download_xls_fulfillments_path(:fulfillment_file_id => ff.id)}' class='btn btn-success'>Download it from here</a>".html_safe
          end
        end       
      rescue Exception => e
        flash.now[:error] = t('error_messages.airbrake_error_message')
        Auditory.report_issue("FulfillmentFile turn inalid when generating it.", e)
        raise ActiveRecord::Rollback
      end
    else
      flash.now[:error] = t('error_messages.fulfillment_file_cant_be_empty')
    end
    render :index
  end

  def download_xls
    my_authorize! :report, Fulfillment, @current_club.id
    FulfillmentFiles::SendEmailWithFileJob.perform_later(fulfillment_file_id: params[:fulfillment_file_id], only_in_progress: params[:only_in_progress])

    flash[:notice] = "We are generating the Fulfillment File requested, and it will be delivered to your configured email as soon as it is ready. Have in mind this could take up to 15 minutes depending on the amount of users and fulfillments involved."

    redirect_to list_fulfillment_files_path
  end

  def mark_file_as_sent
    my_authorize! :report, Fulfillment, @current_club.id
    file = FulfillmentFile.find(params[:fulfillment_file_id])
    if file.sent?
      flash[:notice] = 'Fulfillment file was already marked as sent.'
    elsif file.in_process?
      file.processed!
      flash[:notice] = 'Fulfillment file marked as sent successfully.'
    elsif file.packed?
      file.processed_and_packed!
      flash[:notice] = 'Fulfillment file processed and marked as packed successfully.'
    end
  rescue Exception => e
    flash[:error] = t('error_messages.airbrake_error_message')
    Auditory.report_issue('FulfillmentFile:mark_file_as_sent', e)
  ensure
    redirect_to list_fulfillment_files_path
  end

  def mark_file_as_packed
    my_authorize! :report, Fulfillment, @current_club.id
    file = FulfillmentFile.find(params[:fulfillment_file_id])
    # byebug
    if file.packed?
      flash[:notice] = 'Fulfillment file was already marked as packed.'
    elsif file.in_process?
      file.pack!
      flash[:notice] = 'Fulfillment file marked as packed successfully.'
    else
      flash[:error] = 'Couldn\'t mark file as Packed'
    end
  rescue Exception => e
    flash[:error] = t('error_messages.airbrake_error_message')
    Auditory.report_issue('FulfillmentFile:mark_file_as_packed', e)
  ensure
    redirect_to list_fulfillment_files_path
  end

  def suspected_fulfillments
    my_authorize! :manual_review, Fulfillment, @current_club.id
    params[:initial_date] = params[:initial_date].nil? ? (Time.current - 7.days).to_date : params[:initial_date].to_date
    params[:end_date] = params[:end_date].nil? ? (Time.current).to_date : params[:end_date].to_date

    initial_date = params[:initial_date].in_time_zone(current_club.time_zone).beginning_of_day.utc
    end_date = params[:end_date].in_time_zone(current_club.time_zone).end_of_day.utc

    @suspected_fulfillment_data = Fulfillment.where("status = ? AND club_id = ? AND assigned_at BETWEEN ? and ?", 
                    'manual_review_required', current_club.id, initial_date, end_date).
                    order('created_at DESC').group_by{ |f| f.created_at.to_date }
  end

  def suspected_fulfillment_information
    fulfillment = Fulfillment.find_by(id: params[:id], club_id: current_club.id)
    evidences = fulfillment.suspected_fulfillment_evidences.order("match_age ASC").paginate(page: params[:page], per_page: 20) if fulfillment
    render :partial => 'suspected_fulfillment_information', locals: { fulfillment: fulfillment, evidences: evidences }
  end

  def import_shipping_costs
    if request.post?
      if params[:fulfillment] && params[:fulfillment][:file]
        if (params[:fulfillment][:file].size.to_f / 2**20) <= 4
          if ['application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', 'application/vnd.ms-excel', 'application/xls', 'application/xlsx'].include? params[:fulfillment][:file].content_type
            # create Job to analyze these rows or 
          else
            flash.now[:error] = "Format not supported. Please, provide an xlsx file"
          end
        else
          flash.now[:error] = 'The file is too large. The maximum size of a file is 4Mb.'
        end
      else
        flash.now[:error] = 'The file is required. Please, provide a file before submitting.'
      end
    end
  end
end
