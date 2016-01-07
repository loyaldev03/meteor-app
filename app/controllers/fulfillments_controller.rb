class FulfillmentsController < ApplicationController
  before_filter :validate_club_presence
  layout '', only: [:suspected_fulfillment_information]

  def index
    my_authorize! :report, Fulfillment, @current_club.id
    if request.post?
      @status = params[:status]
      if params[:all_times] == '1'     
        if params[:radio_product_type] == Settings.others_product
          @fulfillments = Fulfillment.includes(:user).joins(:user).where('fulfillments.status = ? and fulfillments.club_id = ?', params[:status], @current_club.id).type_others.not_renewed
        elsif params[:radio_product_type] == Settings.others_product+'_package'
          products = Product.where(club_id: @current_club.id, package: params[:product_type]).pluck(:sku)
          @fulfillments = Fulfillment.where("fulfillments.status = ? AND club_id = ? AND product_sku in (?)", params[:status], @current_club.id, products).not_renewed
        else
          @fulfillments = Fulfillment.includes(:user).joins(:user).where('fulfillments.status = ? and fulfillments.club_id = ? and product_sku = ? ', params[:status], @current_club.id, params[:product_type]).not_renewed
        end
        @product_type = params[:product_type]
      else
        if params[:radio_product_type] == Settings.others_product
          @fulfillments = Fulfillment.includes(:user).joins(:user).where(['fulfillments.status = ? AND date(assigned_at) BETWEEN ? and ? AND fulfillments.club_id = ? ', 
            params[:status], params[:initial_date], params[:end_date], @current_club.id]).type_others.not_renewed
        elsif params[:radio_product_type] == Settings.others_product+'_package'
          products = Product.where(club_id: @current_club.id, package: params[:product_type]).pluck(:sku)
          @fulfillments = Fulfillment.where("fulfillments.status = ? AND date(assigned_at) BETWEEN ? and ? AND club_id = ? and product_sku in (?)", 
            params[:status], params[:initial_date], params[:end_date], @current_club.id, products).not_renewed
        else
          @fulfillments = Fulfillment.includes(:user).joins(:user).where(['fulfillments.status = ? AND date(assigned_at) BETWEEN ? and ? AND fulfillments.club_id = ? AND product_sku = ? ', 
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
    ff.product = params[:product_type]
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
        Auditory.report_issue("FulfillmentFile turn inalid when generating it.", e, { :fulfillment_file => ff.inspect })
        raise ActiveRecord::Rollback
      end
    else
      flash.now[:error] = t('error_messages.fulfillment_file_cant_be_empty')
    end
    render :index
  end

  def download_xls
    my_authorize! :report, Fulfillment, @current_club.id
    fulfillment_file = FulfillmentFile.find(params[:fulfillment_file_id])
    fulfillment_file.send_email_with_file(params[:only_in_progress])

    flash[:notice] = "We are generating the Fulfillment File requested, and it will be delivered to your configured email as soon as it is ready. Have in mind this could take up to 15 minutes depending on the amount of users and fulfillments involved."

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
  rescue Exception => e
    flash[:error] = t('error_messages.airbrake_error_message')
    Auditory.report_issue("FulfillmentFile:mark_file_as_sent", e, { :file => file.inspect })
  ensure
    redirect_to list_fulfillment_files_path
  end

  def suspected_fulfillments
    params[:initial_date] ||= (Time.current - 7.days).to_date
    params[:end_date] ||= (Time.current).to_date
    @suspected_fulfillment_data = Fulfillment.where("status = ? AND club_id = ? AND date(assigned_at) BETWEEN ? and ?", 
                    'manual_review_required', current_club.id, params[:initial_date], params[:end_date]).
                    order('created_at DESC').group_by{ |f| f.created_at.to_date }
  end

  def suspected_fulfillment_information
    fulfillment = Fulfillment.find_by(id: params[:id], club_id: current_club.id)
    evidences = fulfillment.suspected_fulfillment_evidences.paginate(page: params[:page], per_page: 20).order("created_at DESC") if fulfillment
    render :partial => 'suspected_fulfillment_information', locals: { fulfillment: fulfillment, evidences: evidences }
  end
end


