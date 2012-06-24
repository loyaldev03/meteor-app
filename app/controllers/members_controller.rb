class MembersController < ApplicationController
  before_filter :validate_club_presence
  before_filter :validate_member_presence, :except => [ :index, :new ]

  def index
    if request.post?
      @members = Member.paginate(:page => params[:page], :per_page => 10)
                       .with_visible_id(params[:member][:member_id])
                       .with_first_name_like(params[:member][:first_name])
                       .with_last_name_like(params[:member][:last_name])
                       .with_address_like(params[:member][:address])
                       .with_city_like(params[:member][:city])
                       .with_state_like(params[:member][:state])
                       .with_zip(params[:member][:zip])
                       .with_email_like(params[:member][:email])
                       .with_phone_number_like(params[:member][:phone_number])
                       .with_next_retry_bill_date(params[:member][:next_retry_bill_date])
                       .with_credit_card_last_digits(params[:member][:last_digits])
                       .where(:club_id => @current_club)
                       .order(:visible_id)
    end
  end

  def show
    @operation_filter = params[:filter]
    @notes = @current_member.member_notes.paginate(:page => params[:page], :per_page => 10, :order => "created_at DESC")
    @credit_cards = @current_member.credit_cards.all
    @active_credit_card = @current_member.active_credit_card
    @fulfillments = @current_member.fulfillments.all
    @communications = @current_member.communications.all
  end

  def new
    @member = Member.new 
    @terms_of_membership = TermsOfMembership.where(:club_id => @current_club )
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
      if !params[:reason].blank?
        if params[:cancel_date].to_date > Time.zone.now.to_date
          begin
            @current_member.cancel_date = params[:cancel_date]
            @current_member.save!
            message = "Member cancellation scheduled to #{params[:cancel_date]} - Reason: #{params[:reason]}"
            Auditory.audit(current_agent, @current_member, message, @current_member, Settings.operation_types.future_cancel)
            flash[:notice] = message
            redirect_to show_member_path
          rescue Exception => e
            flash[:error] = "Could not cancel member. Ticket sent to IT"
            Airbrake.notify(:error_class => "Member:cancel", :error_message => e)
          end
        else
          flash[:error] = "Cancellation date cant be less or equal than today."
        end
      else
        flash[:error] = "Reason cant be blank."
      end
    end    
  end

  def blacklist
      @blacklist_reason = MemberBlacklistReason.all
    if request.post? 
      if @current_member.update_attribute(:blacklisted, true)
        @current_member.active_credit_card.blacklist
        message = "Blacklisted member. Reason: #{params[:reason]}"
        Auditory.audit(current_agent, @current_member, message, @current_member, Settings.operation_types.cancel)
        flash[:notice] = "Blacklisted member."
        redirect_to show_member_path
      else
        flash[:error] = "Could not blacklisted this member."
        redirect_to show_member_path 
      end
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
          flash[:error] = "Could not set the NBD on this member. #{e}"
        end
      else
        flash[:error] = "Next bill date should be older that actual date."
      end
    end
  end

  def set_undeliverable 
    if request.post?
      if @current_member.update_attribute(:wrong_address, params[:reason])
        message = "Address #{@current_member.full_address} is undeliverable. Reason: #{params[:reason]}"
        flash[:notice] = message
        Auditory.audit(@current_agent,@current_member,message,@current_member)
        redirect_to show_member_path
      else
        flash[:error] = "Could not set the NBD on this member #{@current_member}.errors.inspect"
      end
    end
  end

  def set_unreachable
    if request.post?
      if @current_member.update_attribute(:wrong_phone_number, params[:reason])
        message = "Phone number #{@current_member.phone_number} is  #{params[:reason]}."
        flash[:notice] = message
        Auditory.audit(@current_agent,@current_member,message,@current_member)
        redirect_to show_member_path
      else
        flash[:error] = "Could not set the NBD on this member"
      end
    end
  end

  def resend_fulfillment 
    if request.post?
      fulfillment = Fulfillment.find(params[:fulfillment_id])
      fulfillment.update_attribute :delivered_at, Time.zone.now
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
        errors = cct.errors.collect {|attr, message| "#{attr}: #{message}" }.join(". ")
        flash[:error] = "Could not saved club cash transactions: #{errors}"
      end
    end
  end

  def approve
    if @current_member.can_be_approved?
      @current_member.applied?
      @current_member.set_as_provisional!
      message = "Member was approved."
      Auditory.audit(@current_agent, @current_member, message, @current_member)
    else
      message = "Member cannot be approved. It must be applied."
    end
    redirect_to show_member_path
  end

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
end

