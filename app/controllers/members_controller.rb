class MembersController < ApplicationController
  layout lambda { |c| c.request.xhr? ? false : "application" }

  before_filter :validate_club_presence
  before_filter :validate_member_presence, :except => [ :index, :new, :search_result ]
  authorize_resource :member
  
  def index
     respond_to do |format|
      format.html 
      format.js 
    end
  end

  def search_result
    @members = Member.paginate(:page => params[:page], :per_page => 10)
                       .with_visible_id(params[:member][:member_id])
                       .with_first_name_like(params[:member][:first_name])
                       .with_last_name_like(params[:member][:last_name])
                       .with_address_like(params[:member][:address])
                       .with_city_like(params[:member][:city])
                       .with_state_like(params[:member][:state])
                       .with_zip(params[:member][:zip])
                       .with_email_like(params[:member][:email])
                       .with_next_retry_bill_date(params[:member][:next_retry_bill_date])
                       .with_credit_card_last_digits(params[:member][:last_digits])
                       .with_member_notes(params[:member][:notes])
                       .with_phone_country_code(params[:member][:phone_country_code])
                       .with_phone_area_code(params[:member][:phone_area_code])
                       .with_phone_local_number(params[:member][:phone_local_number])
                       .with_sync_status(params[:member][:sync_status])
                       .with_external_id(params[:member][:external_id])
                       .where(:club_id => @current_club)
                       .needs_approval(params[:member][:needs_approval])
                       .order(:visible_id)
                       .uniq
    respond_to do |format|
      format.html {render 'index'}
      format.js {render 'index'}
    end
  end

  def show
    @operation_filter = params[:filter]
    @notes = @current_member.member_notes.paginate(:page => params[:page], :per_page => 10, :order => "created_at DESC")
    @credit_cards = @current_member.credit_cards.all
    @active_credit_card = @current_member.active_credit_card
    @fulfillments = @current_member.fulfillments.all
    @communications = @current_member.communications.all
    @enrollment_info = @current_member.enrollment_infos.first
  end

  def new
    @member = Member.new
    @credit_card = @member.credit_cards.build
    @terms_of_memberships = TermsOfMembership.where(:club_id => @current_club )
    @enrollment_info = @member.enrollment_infos.build
  end

  def edit  
    @member = @current_member
    @member_group_types = MemberGroupType.find_all_by_club_id(@current_club)
  end

  def save_the_sale
    if request.post?
      if TermsOfMembership.find_by_id_and_club_id(params[:terms_of_membership_id], @current_club.id).nil?
        flash[:error] = "Terms of membership not found"
        redirect_to show_member_path
      else
        answer = @current_member.save_the_sale(params[:terms_of_membership_id], current_agent)
        if answer[:code] == Settings.error_codes.success
          flash[:notice] = "Save the sale succesfully applied"
          redirect_to show_member_path
        else
          flash.now[:error] = answer[:message]
        end
      end
    end
  end

  def recover
    if request.post?
      answer = @current_member.recover(@current_member.terms_of_membership_id, current_agent)
      if answer[:code] == Settings.error_codes.success
        flash[:notice] = answer[:message]
      else
        flash[:error] = answer[:message]
      end
    end
    redirect_to show_member_path
  end

  def refund
    @transaction = Transaction.find_by_uuid_and_member_id params[:transaction_id], @current_member.uuid
    if @transaction.nil?
      flash[:error] = "Transaction not found."
      redirect_to show_member_path
      return
    end
    if request.post?
      answer = Transaction.refund(params[:refund_amount], params[:transaction_id], current_agent)
      if answer[:code] == Settings.error_codes.success
        flash[:notice] = answer[:message]
        redirect_to show_member_path
      else
        flash.now[:error] = answer[:message]
      end
    end
  end

  def full_save
    message = "Full save done"
    Auditory.audit(@current_agent, nil, message, @current_member, Settings.operation_types.full_save)
    flash[:notice] = message
    redirect_to show_member_path
  end

  def cancel
    @member_cancel_reason = MemberCancelReason.all
    if request.post?
      unless params[:reason].blank?
        if params[:cancel_date].to_date > Time.zone.now.to_date
          begin
            message = "Member cancellation scheduled to #{params[:cancel_date]} - Reason: #{params[:reason]}"
            @current_member.cancel! params[:cancel_date], message, current_agent
            flash[:notice] = message
            redirect_to show_member_path
          rescue Exception => e
            flash.now[:error] = "Could not cancel member. Ticket sent to IT"
            Airbrake.notify(:error_class => "Member:cancel", :error_message => e)
          end
        else
          flash.now[:error] = "Cancellation date cant be less or equal than today."
        end
      else
        flash.now[:error] = "Reason cant be blank."
      end
    end    
  end

  def blacklist
    @blacklist_reasons = MemberBlacklistReason.all
    if request.post? 
      response = @current_member.blacklist(@current_agent, params[:reason])
      if response[:success]
        flash[:notice] = response[:message]
      else
        flash[:error] = response[:message]
      end
      redirect_to show_member_path
    end
  end

  def change_next_bill_date
    if request.post?
      if params[:next_bill_date].to_date > Time.zone.now.to_date
        begin
          @current_member.change_next_bill_date!(params[:next_bill_date])
          message = "Next bill date changed to #{params[:next_bill_date]}"
          Auditory.audit(current_agent, @current_member, message, @current_member, Settings.operation_types.change_next_bill_date)
          flash[:notice] = message
          redirect_to show_member_path
        rescue Exception => e
          flash.now[:error] = "Could not set the NBD on this member. Ticket sent to IT"
          Airbrake.notify(:error_class => "Member:change_next_bill_date", :error_message => e)
        end
      else
        flash.now[:error] = "Next bill date should be older that actual date."
      end
    end
  end

  def set_undeliverable 
    if request.post?
      answer = @current_member.set_wrong_address(@current_agent, params[:reason])
      if answer[:code] == Settings.error_codes.success
        flash.now[:notice] = answer[:message]
      else
        flash.now[:error] = answer[:message]
      end
      respond_to do |format|
        format.html { redirect_to show_member_path }
        format.json { render json: { :message => answer[:message], :code => answer[:code] }} 
      end
    end

  end

  def set_unreachable
    if request.post?
      if @current_member.update_attribute(:wrong_phone_number, params[:reason])
        message = "Phone number #{@current_member.full_phone_number} is #{params[:reason]}."
        flash[:notice] = message
        Auditory.audit(@current_agent,@current_member,message,@current_member)
        redirect_to show_member_path
      else
        flash.now[:error] = "Could not set phone number as unreachable."
      end
    end
  end

  def resend_fulfillment 
    if request.post?
      fulfillment = Fulfillment.find(params[:fulfillment_id])
      message = "Resend fulfillment #{fulfillment.product}."
      Auditory.audit(@current_agent,@current_member,message,@current_member)    
      flash[:notice] = message 
      redirect_to show_member_path
    end
  end

  def add_club_cash
    if request.post?
      cct = ClubCashTransaction.new(params[:club_cash_transaction])
      cct.member_id = @current_member
      
      if cct.save
        message = "Club cash transaction done!. Amount: $#{cct.amount}"
        Auditory.audit(@current_agent, cct, message, @current_member)
        flash[:notice] = message
        redirect_to show_member_path
      else
        flash.now[:error] = "Could not saved club cash transactions: #{cct.error_to_s}"
      end
    end
  end

  # TODO: show message in flash
  def approve
    if @current_member.can_be_approved?
      @current_member.set_as_provisional!
      message = "Member was approved."
      Auditory.audit(@current_agent, @current_member, message, @current_member)
    else
      message = "Member cannot be approved. It must be applied."
    end
    redirect_to show_member_path
  end

  # TODO: show message in flash
  def reject
    if @current_member.can_be_rejected?
      @current_member.set_as_canceled!
      message = "Member was rejected and setted as canceled."
      Auditory.audit(@current_agent, @current_member, message, @current_member)
    else
      message = "Member cannot be rejected. It must be applied."
    end
    redirect_to show_member_path  
  end

  def login_as_member
    am = @current_member.api_member

    if am
      if (lt = am.login_token) && lt.url
        redirect_to @current_member.full_autologin_url.to_s
      else
        flash[:error] = "There is no url related to the member in drupal."
        redirect_to show_member_path
      end
    else
      flash[:error] = "There is no member in drupal."
      redirect_to show_member_path
    end
  end

  def update_sync
    old_id = @current_member.api_id
    if params[:member] && @current_member.update_attribute(:api_id, params[:member][:api_id])
      message = "Member's api_id changed from #{old_id.inspect} to #{@current_member.api_id.inspect}"
      Auditory.audit(@current_agent, @current_member, message, @current_member)
      redirect_to show_member_path, notice: 'Sync data updated'
    else
      redirect_to show_member_path, notice: 'Sync data cannot be updated'
    end
  end

  def sync
    am = @current_member.api_member
    if am
      am.save!(force: true)
      if @current_member.last_sync_error_at
        message = "Synchronization failed: #{@current_member.last_sync_error}"
      else
        message = "Member synchronized"
      end
      Auditory.audit(@current_agent, @current_member, message, @current_member)
      redirect_to show_member_path, notice: message
    end
  rescue
    message = "Error on members#sync: #{$!}"
    Auditory.audit(@current_agent, @current_member, message, @current_member)
    redirect_to show_member_path, notice: message
  end

  def sync_data
    @api_member = @current_member.api_member
    @data = @api_member.get
    respond_to do |format|
      format.html 
    end
  end

  def reset_password
    am = @current_member.api_member
    if am && am.reset_password!
      message = "Remote password reset successful"
    else
      message = "Remote password could not be reset"
    end
    Auditory.audit(@current_agent, @current_member, message, @current_member)
    redirect_to show_member_path, notice: message
  rescue
    message = "Error on members#reset_password: #{$!}"
    Auditory.audit(@current_agent, @current_member, message, @current_member)
    redirect_to show_member_path, notice: message
  end

  def resend_welcome
    am = @current_member.api_member
    if am && am.resend_welcome_email!
      message = "Resend welcome email successful"
    else
      message = "Welcome email could not be resent"
    end
    Auditory.audit(@current_agent, @current_member, message, @current_member)
    redirect_to show_member_path, notice: message
  rescue
    message = "Error on members#resend_welcome: #{$!}"
    Auditory.audit(@current_agent, @current_member, message, @current_member)
    redirect_to show_member_path, notice: message
  end
end

