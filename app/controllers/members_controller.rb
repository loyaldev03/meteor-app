class MembersController < ApplicationController
  layout lambda { |c| c.request.xhr? ? false : "application" }

  before_filter :validate_club_presence
  before_filter :validate_member_presence, :except => [ :index, :new, :search_result ]
  before_filter :check_permissions, :except => [ :additional_data ]
  
  def index
    @countries = Carmen::Country.coded('US').subregions + Carmen::Country.coded('CA').subregions
    respond_to do |format|
      format.html
      format.js
    end
  end

  def additional_data
    my_authorize! :update, MemberAdditionalData, @current_club.id
    if request.post?
      @form = @current_member.additional_data_form.new params
      if @form.valid?
        @current_member.update_attribute :additional_data, @form.cleaned_data
        redirect_to show_member_path, notice: 'Additional data updated with success'
      end
    else
      @form = @current_member.additional_data_form.new @current_member.additional_data
    end
  end

  def search_result
    current_club = @current_club
    @members = Member.search do
      # members
      [ :first_name, :last_name, :address, :city, :zip, :email, :external_id, :notes ].each do |field|
        fulltext("*#{params[:member][field].strip}*", :fields => field) unless params[:member][field].blank?
      end
      [ :id, :state, :country, :phone_country_code, :phone_area_code, :phone_local_number, :last_digits, :cc_token ].each do |field|
        with(field, params[:member][field].strip) unless params[:member][field].blank?
      end
      if params[:member][:needs_approval].to_i != 0
        with(:status, 'applied')
      end
      unless params[:member][:next_retry_bill_date].blank?
        next_retry_bill_date = params[:member][:next_retry_bill_date].to_date.to_time_in_current_zone
        with(:next_retry_bill_date, next_retry_bill_date.beginning_of_day..next_retry_bill_date.end_of_day)
      end
      case params[:member][:sync_status]
        when true, 'true', 'synced'
          with :sync_status, "synced"
        when false, 'false', 'unsynced'
          with :sync_status, "not_synced"
        when 'error'
          with :sync_status, "with_error"
        when 'noerror'
          with :sync_status, ["not_synced", "synced"]
      end
      unless params[:member][:billing_date_start].blank?
        billing_date_start = params[:member][:billing_date_start].to_date.to_time_in_current_zone
        with(:billed_dates).greater_than(billing_date_start)
      end
      unless params[:member][:billing_date_end].blank?
        billing_date_end = params[:member][:billing_date_end].to_date.to_time_in_current_zone
        with(:billed_dates).less_than(billing_date_end)
      end
      with :club_id, current_club.id
      order_by sort_column, sort_direction
      paginate :page => params[:page], :per_page => 25
    end.results
  rescue Errno::ECONNREFUSED
    @solr_is_down = true
    Auditory.report_issue("Member:search_result", "SOLR is down. Confirm that server is running, if problem persist restart it")
  rescue Errno::ETIMEDOUT
    @solr_is_down = true
    Auditory.report_issue("Member:search_result", "SOLR Timeout Error received. Confirm that service is available.")  
  ensure
    render 'index'
  end

  def show
    @operation_filter = params[:filter]
    @current_membership = @current_member.current_membership
    @active_credit_card = @current_member.active_credit_card
  end

  def new
    @member = Member.new
    @credit_card = @member.credit_cards.build
    @terms_of_memberships = TermsOfMembership.where(:club_id => @current_club )
    @enrollment_info = @member.enrollment_infos.build
    @months = 1..12
    @years = Time.zone.now.year.upto(Time.zone.now.year+20).to_a
  end

  def edit  
    @member = @current_member
    @member_group_types = MemberGroupType.find_all_by_club_id(@current_club)
    @country = Carmen::Country.coded(@member.country)
    @months = 1..12
    @years = Time.zone.now.year.upto(Time.zone.now.year+20).to_a
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
      tom = TermsOfMembership.find_by_id_and_club_id(params[:terms_of_membership_id], @current_club.id)
      if tom.nil?
        flash[:error] = "Terms of membership not found"
      else
        answer = @current_member.recover(tom, current_agent, 
          { landing_url: request.env['HTTP_HOST'], referral_path: request.env['REQUEST_URI'], ip_address: request.env['REMOTE_ADDR'] })
        if answer[:code] == Settings.error_codes.success
          flash[:notice] = answer[:message]
        else
          flash[:error] = answer[:message] + " " + ( answer[:errors].nil? ? " " : answer[:errors].collect {|attr, message| "#{attr}: #{message}" }.join(' ') )
        end
      end
      redirect_to show_member_path
    end
  end

  def refund
    @transaction = Transaction.find_by_uuid_and_member_id params[:transaction_id], @current_member.id
    if @transaction.nil?
      flash[:error] = "Transaction not found."
      redirect_to show_member_path
      return
    elsif not @transaction.can_be_refunded?
      flash[:error] = "Transaction cannot be refunded."
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
      begin
        response = @current_member.cancel! params[:cancel_date], params[:reason], current_agent
        if response[:code] == Settings.error_codes.success
          flash[:notice] = response[:message]
          redirect_to show_member_path
        else
          flash.now[:error] = response[:message]
        end
      rescue Exception => e
        flash.now[:error] = t('error_messages.airbrake_error_message')
        Auditory.report_issue("Member:cancel", e, { :member => @current_member.inspect })
      end
    end
  end

  def blacklist
    @blacklist_reasons = MemberBlacklistReason.all
    if request.post? 
      response = @current_member.blacklist(@current_agent, params[:reason])
      if response[:code] == Settings.error_codes.success
        flash[:notice] = response[:message] 
      else
        flash[:error] = response[:message]
      end
      redirect_to show_member_path  
    end
  end

  def change_next_bill_date
    if request.post?
      answer = @current_member.change_next_bill_date(params[:next_bill_date], @current_agent)
      if answer[:code] == Settings.error_codes.success
        flash[:notice] = answer[:message]
        redirect_to show_member_path
      else
        flash.now[:error] = answer[:message]
        @errors = answer[:errors]
      end  
    end
  end

  def set_undeliverable 
    if request.post?
      answer = @current_member.set_wrong_address(@current_agent, params[:reason])
      if answer[:code] == Settings.error_codes.success
        flash[:notice] = answer[:message]
      else
        flash[:error] = answer[:message]
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
        Auditory.audit(@current_agent,@current_member,message,@current_member, Settings.operation_types.phone_number_set_unreachable)
        redirect_to show_member_path
      else
        flash.now[:error] = "Could not set phone number as unreachable."
      end
    end
  end

  def approve
    if @current_member.can_be_approved?
      @current_member.set_as_provisional!
      message = "Member approved"
      Auditory.audit(@current_agent, @current_member, message, @current_member, Settings.operation_types.member_approved)
      flash[:notice] = message
    else
      flash[:error] = "Member cannot be approved. It must be applied."
    end
    redirect_to show_member_path
  end

  def reject
    if @current_member.can_be_rejected?
      @current_member.set_as_canceled!
      message = "Member was rejected and now its lapsed."
      Auditory.audit(@current_agent, @current_member, message, @current_member, Settings.operation_types.member_rejected)
      flash[:notice] = message
    else
      flash[:error] = "Member cannot be rejected. It must be applied."
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
    if params[:member]
      if params[:member][:api_id].blank?
        @current_member.skip_api_sync!
        @current_member.api_id = nil
        @current_member.last_sync_error = nil
        @current_member.last_sync_error_at = nil
        @current_member.last_synced_at = nil
        @current_member.sync_status = "not_synced"
      else
        @current_member.api_id = params[:member][:api_id].strip
      end
      begin
        if @current_member.save
          message = "Member's api_id changed from #{old_id.inspect} to #{@current_member.api_id.inspect}"
          Auditory.audit(@current_agent, @current_member, message, @current_member, Settings.operation_types.member_drupal_remote_id_set)
          redirect_to show_member_path, notice: 'Sync data updated'
        else
          flash[:error] = "Sync data cannot be updated #{@current_member.errors.to_hash}"
          redirect_to show_member_path
        end
      rescue ActiveRecord::RecordNotUnique
        flash[:error] = "Sync data cannot be updated. Api id already exists"
        redirect_to show_member_path
      end
    end
  end

  def sync
    am = @current_member.api_member
    if am
      am.save!(force: true)
      if @current_member.last_sync_error_at
        message = "Synchronization failed: #{@current_member.last_sync_error ? @current_member.last_sync_error.html_safe : ''}"
      else
        message = "Member synchronized"
      end
      Auditory.audit(@current_agent, @current_member, message, @current_member, Settings.operation_types.member_manually_synced_to_drupal)
      redirect_to show_member_path, notice: message    
    end
  rescue
    flash[:error] = t('error_messages.airbrake_error_message')
    message = "Error on members#sync: #{$!}" 
    Auditory.report_issue("Member:sync", message, { :member => @current_member.inspect })
    redirect_to show_member_path
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
    Auditory.audit(@current_agent, @current_member, message, @current_member, Settings.operation_types.reset_password)
    redirect_to show_member_path, notice: message
  rescue
    flash[:error] = t('error_messages.airbrake_error_message')
    message = "Error on members#reset_password: #{$!}"
    Auditory.report_issue("Member:reset_password", message, { :member => @current_member.inspect })
    redirect_to show_member_path
  end

  def resend_welcome
    am = @current_member.api_member
    if am && am.resend_welcome_email!
      message = "Resend welcome email successful"
    else
      message = "Welcome email could not be resent"
    end
    Auditory.audit(@current_agent, @current_member, message, @current_member, Settings.operation_types.resend_welcome)
    redirect_to show_member_path, notice: message
  rescue
    flash[:error] = t('error_messages.airbrake_error_message')
    message = "Error on members#resend_welcome: #{$!}"
    Auditory.report_issue("Member:resend_welcome", message, { :member => @current_member.inspect })
    redirect_to show_member_path
  end

  def no_recurrent_billing
    if request.post?
      answer = @current_member.no_recurrent_billing(params[:amount], params[:description], params[:type])
      if answer[:code] == Settings.error_codes.success
        flash[:notice] = answer[:message]
        redirect_to show_member_path
      else
        flash.now[:error] = answer[:message]
      end
    end
  end

  def manual_billing
    @tom = @current_member.current_membership.terms_of_membership
    if request.post?
      answer = @current_member.manual_billing(params[:amount], params[:payment_type])
      if answer[:code] == Settings.error_codes.success
        flash[:notice] = answer[:message]
        redirect_to show_member_path
      else
        flash.now[:error] = answer[:message]
      end
    end
  end

  def transactions_content
    render :partial => 'members/transactions'
  end

  def notes_content
    @notes = @current_member.member_notes.includes([ :communication_type, :disposition_type ]).paginate(:page => params[:page], :per_page => 10, :order => "created_at DESC")
    render :partial => 'members/notes', :locals => { :notes => @notes }
  end

  def fulfillments_content
    @fulfillments = @current_member.fulfillments.all
    render :partial => "members/fulfillments", :locals => { :fulfillments => @fulfillments }
  end

  def communications_content
    @communications = @current_member.communications.all
    render :partial => 'members/communications', :locals => { :communications => @communications }
  end

  def operations_content
    render :partial => 'members/operations'
  end

  def credit_cards_content 
    @credit_cards = @current_member.credit_cards.all
    render :partial => 'members/credit_cards', :locals => { :credit_cards => @credit_cards }
  end

  def club_cash_transactions_content
    render :partial => 'members/club_cash_transactions'
  end

  def memberships_content
    render :partial => 'members/memberships'
  end

  private 
    def sort_column
      @sort_column ||= ['status', 'id', 'full_name', 'full_address' ].include?(params[:sort]) ? params[:sort] : 'join_date'
    end
    
    def sort_direction
      @sort_direction ||= %w[asc desc].include?(params[:direction]) ? params[:direction] : 'desc'
    end

    def check_permissions
      my_authorize! params[:action].to_sym, Member, @current_club.id
    end
end

