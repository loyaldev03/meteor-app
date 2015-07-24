class UsersController < ApplicationController
  layout lambda { |c| c.request.xhr? ? false : "application" }

  before_filter :validate_club_presence
  before_filter :validate_user_presence, :except => [ :index, :new, :search_result ]
  before_filter :check_permissions, :except => [ :additional_data, :transactions_content, :notes_content, 
                                                 :fulfillments_content, :communications_content, 
                                                 :operations_content, :credit_cards_content, 
                                                 :club_cash_transactions_content, :memberships_content ]
  
  def index
    @countries = Carmen::Country.coded('US').subregions + Carmen::Country.coded('CA').subregions
    respond_to do |format|
      format.html
      format.js
    end
  end

  def additional_data
    my_authorize! :update, UserAdditionalData, @current_club.id
    if request.post?
      @form = @current_user.additional_data_form.new params
      if @form.valid?
        @current_user.update_attribute :additional_data, @form.cleaned_data
        redirect_to show_user_path, notice: 'Additional data updated with success'
      end
    else
      @form = @current_user.additional_data_form.new @current_user.additional_data
    end
  end

  def search_result
    current_club = @current_club
    query_param = "club_id:#{current_club.id}"
    [ :id, :first_name, :last_name, :city, :email, :country, :state, :zip, :cc_last_digits, :status ].each do |field|
      query_param << " #{field}:#{sanitize_string_for_elasticsearch_string_query(field,params[:user][field].strip)}" unless params[:user][field].blank?
    end
    sort_column = @sort_column = params[:sort].nil? ? :id : params[:sort]
    sort_direction = @sort_direction = params[:direction].nil? ? 'desc' : params[:direction]

    @users = User.search(:load => true, :page => (params[:page] || 1), per_page: 20) do
      query { string query_param, :default_operator => "AND" }
      sort { by sort_column, sort_direction }
    end
  rescue Errno::ECONNREFUSED
    @elasticsearch_is_down = true
    Auditory.report_issue("User:search_result", "Elasticsearch is down. Confirm that server is running, if problem persist restart it")
  rescue Errno::ETIMEDOUT
    @elasticsearch_is_down = true
    Auditory.report_issue("User:search_result", "Elasticsearch Timeout Error received. Confirm that service is available.")  
  ensure
    render 'index'
  end

  def show
    @operation_filter = params[:filter]
    @current_membership = @current_user.current_membership
    @active_credit_card = @current_user.active_credit_card
  end

  def new
    @user = User.new
    @credit_card = @user.credit_cards.build
    @terms_of_memberships = TermsOfMembership.where(:club_id => @current_club )
    @enrollment_info = @user.enrollment_infos.build
    @months = 1..12
    @years = Time.zone.now.year.upto(Time.zone.now.year+20).to_a
  end

  def edit  
    @user = @current_user
    @member_group_types = MemberGroupType.find_all_by_club_id(@current_club)
    @country = Carmen::Country.coded(@user.country)
    @months = 1..12
    @years = Time.zone.now.year.upto(Time.zone.now.year+20).to_a
  end

  def save_the_sale
    if request.post?
      if TermsOfMembership.find_by_id_and_club_id(params[:terms_of_membership_id], @current_club.id).nil?
        flash[:error] = "Terms of membership not found"
        redirect_to show_user_path
      else
        answer = @current_user.save_the_sale(params[:terms_of_membership_id], current_agent)
        if answer[:code] == Settings.error_codes.success
          flash[:notice] = "Save the sale succesfully applied"
          redirect_to show_user_path
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
        answer = @current_user.recover(tom, current_agent, 
          { landing_url: request.env['HTTP_HOST'], referral_path: request.env['REQUEST_URI'], ip_address: request.env['REMOTE_ADDR'] })
        if answer[:code] == Settings.error_codes.success
          flash[:notice] = answer[:message]
        else
          flash[:error] = answer[:message] + " " + ( answer[:errors].nil? ? " " : answer[:errors].collect {|attr, message| "#{attr}: #{message}" }.join(' ') )
        end
      end
      redirect_to show_user_path
    end
  end

  def refund
    @transaction = Transaction.find_by_id_and_user_id params[:transaction_id], @current_user.id
    if @transaction.nil?
      flash[:error] = "Transaction not found."
      redirect_to show_user_path
      return
    elsif not @transaction.can_be_refunded?
      flash[:error] = "Transaction cannot be refunded."
      redirect_to show_user_path
      return
    end
    if request.post?
      answer = Transaction.refund(params[:refund_amount], params[:transaction_id], current_agent)
      if answer[:code] == Settings.error_codes.success
        flash[:notice] = answer[:message]
        redirect_to show_user_path
      else
        flash.now[:error] = answer[:message]
      end
    end
  end

  def chargeback
    @transaction = Transaction.find(params[:transaction_id])
    unless @transaction.can_be_chargeback?
      flash[:error] = I18n.t("error_messages.cannot_chargeback_transaction")
      redirect_to show_user_path
    end
    
    if request.post?
      if params[:amount].to_f > @transaction.amount_available_to_refund
        flash.now[:error] = I18n.t("error_messages.chargeback_amount_greater_than_available")
      else
        begin
          @current_user.chargeback!(@transaction, { reason: params[:reason], transaction_amount: params[:amount], adjudication_date: params[:adjudication_date], sale_transaction_id: @transaction.id })
          flash[:notice] = "User successfully chargebacked."
          redirect_to show_user_path
        rescue
          flash.now[:error] = "There has been an error. #{$!.to_s}"
        end
      end
    end
  end

  def full_save
    message = "Full save done"
    Auditory.audit(@current_agent, nil, message, @current_user, Settings.operation_types.full_save)
    flash[:notice] = message
    redirect_to show_user_path
  end

  def cancel
    @user_cancel_reason = MemberCancelReason.all
    if request.post?
      begin
        response = @current_user.cancel! params[:cancel_date], params[:reason], current_agent
        if response[:code] == Settings.error_codes.success
          flash[:notice] = response[:message]
          redirect_to show_user_path
        else
          flash.now[:error] = response[:message]
        end
      rescue Exception => e
        flash.now[:error] = t('error_messages.airbrake_error_message')
        Auditory.report_issue("User:cancel", e, { :user => @current_user.inspect })
      end
    end
  end

  def blacklist
    @blacklist_reasons = MemberBlacklistReason.all
    if request.post? 
      response = @current_user.blacklist(@current_agent, params[:reason])
      if response[:code] == Settings.error_codes.success
        flash[:notice] = response[:message] 
      else
        flash[:error] = response[:message]
      end
      redirect_to show_user_path  
    end
  end

  def change_next_bill_date
    if request.post?
      answer = @current_user.change_next_bill_date(params[:next_bill_date], @current_agent)
      if answer[:code] == Settings.error_codes.success
        flash[:notice] = answer[:message]
        redirect_to show_user_path
      else
        flash.now[:error] = answer[:message]
        @errors = answer[:errors]
      end  
    end
  end

  def set_undeliverable 
    if request.post?
      answer = @current_user.set_wrong_address(@current_agent, params[:reason])
      if answer[:code] == Settings.error_codes.success
        flash[:notice] = answer[:message]
      else
        flash[:error] = answer[:message]
      end
      respond_to do |format|
        format.html { redirect_to show_user_path }
        format.json { render json: { :message => answer[:message], :code => answer[:code] }} 
      end
    end
  end

  def set_unreachable
    if request.post?
      if @current_user.update_attribute(:wrong_phone_number, params[:reason])
        message = "Phone number #{@current_user.full_phone_number} is #{params[:reason]}."
        flash[:notice] = message
        Auditory.audit(@current_agent,@current_user,message,@current_user, Settings.operation_types.phone_number_set_unreachable)
        redirect_to show_user_path
      else
        flash.now[:error] = "Could not set phone number as unreachable."
      end
    end
  end

  def approve
    if @current_user.can_be_approved?
      @current_user.set_as_provisional!
      message = "User approved"
      Auditory.audit(@current_agent, @current_user, message, @current_user, Settings.operation_types.user_approved)
      flash[:notice] = message
    else
      flash[:error] = "User cannot be approved. It must be applied."
    end
    redirect_to show_user_path
  end

  def reject
    if @current_user.can_be_rejected?
      @current_user.set_as_canceled!
      message = "Member was rejected and now its lapsed."
      Auditory.audit(@current_agent, @current_user, message, @current_user, Settings.operation_types.user_rejected)
      flash[:notice] = message
    else
      flash[:error] = "User cannot be rejected. It must be applied."
    end
    redirect_to show_user_path  
  end

  def login_as_user
    am = @current_user.api_user

    if am
      if (lt = am.login_token) && lt.url
        redirect_to @current_user.full_autologin_url.to_s
      else
        flash[:error] = "There is no url related to the user in drupal."
        redirect_to show_user_path
      end
    else
      flash[:error] = "There is no user in drupal."
      redirect_to show_user_path
    end
  end

  def update_sync
    old_id = @current_user.api_id
    if params[:user]
      if params[:user][:api_id].blank?
        @current_user.skip_api_sync!
        @current_user.api_id = nil
        @current_user.last_sync_error = nil
        @current_user.last_sync_error_at = nil
        @current_user.last_synced_at = nil
        @current_user.sync_status = "not_synced"
      else
        @current_user.api_id = params[:user][:api_id].strip
      end
      begin
        if @current_user.save
          message = "User's api_id changed from #{old_id.inspect} to #{@current_user.api_id.inspect}"
          Auditory.audit(@current_agent, @current_user, message, @current_user, Settings.operation_types.user_drupal_remote_id_set)
          redirect_to show_user_path, notice: 'Sync data updated'
        else
          flash[:error] = "Sync data cannot be updated #{@current_user.errors.to_hash}"
          redirect_to show_user_path
        end
      rescue ActiveRecord::RecordNotUnique
        flash[:error] = "Sync data cannot be updated. Api id already exists"
        redirect_to show_user_path
      end
    end
  end

  def sync
    am = @current_user.api_user
    if am
      am.save!(force: true)
      if @current_user.last_sync_error_at
        message = "Synchronization failed: #{@current_user.last_sync_error ? @current_user.last_sync_error.html_safe : ''}"
      else
        message = "Member synchronized"
      end
      Auditory.audit(@current_agent, @current_user, message, @current_user, Settings.operation_types.user_manually_synced_to_drupal)
      redirect_to show_user_path, notice: message    
    end
  rescue Exception => e
    flash[:error] = t('error_messages.airbrake_error_message')
    Auditory.report_issue("User:sync", e, { :user => @current_user.inspect })
    redirect_to show_user_path
  end

  def sync_data
    @api_user = @current_user.api_user
    @data = @api_user.get
    respond_to do |format|
      format.html 
    end
  end

  def reset_password
    am = @current_user.api_user
    if am && am.reset_password!
      message = "Remote password reset successful"
    else
      message = "Remote password could not be reset"
    end
    Auditory.audit(@current_agent, @current_user, message, @current_user, Settings.operation_types.reset_password)
    redirect_to show_user_path, notice: message
  rescue Exception => e
    flash[:error] = t('error_messages.airbrake_error_message')
    Auditory.report_issue("User:reset_password", e, { :user => @current_user.inspect })
    redirect_to show_user_path
  end

  def resend_welcome
    am = @current_user.api_user
    if am && am.resend_welcome_email!
      message = "Resend welcome email successful"
    else
      message = "Welcome email could not be resent"
    end
    Auditory.audit(@current_agent, @current_user, message, @current_user, Settings.operation_types.resend_welcome)
    redirect_to show_user_path, notice: message
  rescue Exception => e
    flash[:error] = t('error_messages.airbrake_error_message')
    Auditory.report_issue("User:resend_welcome", e, { :user => @current_user.inspect })
    redirect_to show_user_path
  end

  def no_recurrent_billing
    if request.post?
      answer = @current_user.no_recurrent_billing(params[:amount], params[:description], params[:type])
      if answer[:code] == Settings.error_codes.success
        flash[:notice] = answer[:message]
        redirect_to show_user_path
      else
        flash.now[:error] = answer[:message]
      end
    end
  end

  def manual_billing
    @tom = @current_user.current_membership.terms_of_membership
    if request.post?
      answer = @current_user.manual_billing(params[:amount], params[:payment_type])
      if answer[:code] == Settings.error_codes.success
        flash[:notice] = answer[:message]
        redirect_to show_user_path
      else
        flash.now[:error] = answer[:message]
      end
    end
  end

  def transactions_content
    my_authorize! :list, Transaction, @current_club.id
    render :partial => 'users/transactions'
  end

  def notes_content
    my_authorize! :list, UserNote, @current_club.id
    @notes = @current_user.user_notes.includes([ :communication_type, :disposition_type ]).paginate(:page => params[:page], :per_page => 10, :order => "created_at DESC")
    render :partial => 'users/notes', :locals => { :notes => @notes }
  end

  def fulfillments_content
    my_authorize! :list, Fulfillment, @current_club.id
    @fulfillments = @current_user.fulfillments.all
    render :partial => "users/fulfillments", :locals => { :fulfillments => @fulfillments }
  end

  def communications_content
    my_authorize! :list, Communication, @current_club.id
    @communications = @current_user.communications.all
    render :partial => 'users/communications', :locals => { :communications => @communications }
  end

  def operations_content
    my_authorize! :list, Operation, @current_club.id
    render :partial => 'users/operations'
  end

  def credit_cards_content 
    my_authorize! :list, CreditCard, @current_club.id
    @credit_cards = @current_user.credit_cards.all
    render :partial => 'users/credit_cards', :locals => { :credit_cards => @credit_cards }
  end

  def club_cash_transactions_content
    my_authorize! :list, ClubCashTransaction, @current_club.id
    render :partial => 'users/club_cash_transactions'
  end

  def memberships_content
    my_authorize! :list, Membership, @current_club.id
    render :partial => 'users/memberships'
  end

  private 
    def sort_column
      @sort_column ||= ['status', 'id', 'full_name', 'full_address' ].include?(params[:sort]) ? params[:sort] : 'join_date'
    end
    
    def sort_direction
      @sort_direction ||= %w[asc desc].include?(params[:direction]) ? params[:direction] : 'desc'
    end

    def check_permissions
      my_authorize! params[:action].to_sym, User, @current_club.id
    end

    def sanitize_string_for_elasticsearch_string_query(field, value)
      escaped_characters = Regexp.escape('\\-+&|!(){}[]^~?:@')
      value = value.gsub(/([#{escaped_characters}])/, '\\\\\1')
      ['AND', 'OR', 'NOT'].each do |word|
        escaped_word = word.split('').map {|char| "\\#{char}" }.join('')
        value = value.gsub(/\s*\b(#{word.upcase})\b\s*/, " #{escaped_word} ")
      end
      quote_count = value.count '"'
      value = value.gsub(/(.*)"(.*)/, '\1\"\3') if quote_count % 2 == 1 
      field == :id ? "#{value}".gsub(/[^\d]/,"") : "*#{value}*".gsub(" ","* *")
    end
end

