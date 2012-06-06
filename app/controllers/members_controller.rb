class MembersController < ApplicationController
  before_filter :validate_club_presence
  before_filter :validate_member_presence, :except => [ :index, :new ]

  def index
    if request.post?
      #We will be validating two fields because we have to make sure that they will never be 'null',
      #so as keep our search working properly. (If some of them are null the query wont bring us anything 'null')
      #If we don't fill the member_id field.  
      params[:member][:member_id].blank? ? member_id = '%' : member_id = params[:member][:member_id]
      #In case we don't fill the last_digits field.
      params[:member][:last_digits].blank? ? last_digits = '%' : last_digits = params[:member][:last_digits]
      params[:member][:bill_date].blank? ? member_status = ['lapsed','provisional','active'] : member_status = ['provisional','active']
      @members = Member.joins(:credit_cards).where(["visible_id like ? AND first_name like ? AND last_name like ? 
                 AND address like ? AND phone_number like ? AND city like ? AND state like ? AND zip like ? AND email like ? 
                 AND (bill_date like ? OR bill_date is null) AND club_id like ? AND (credit_cards.active = 1 
                 AND credit_cards.last_digits like ?) AND status in (?)", 
                 member_id,'%'+params[:member][:first_name]+'%',
                 '%'+params[:member][:last_name]+'%','%'+params[:member][:address]+'%',
                 '%'+params[:member][:phone_number]+'%','%'+params[:member][:city]+'%',
                 '%'+params[:member][:state]+'%','%'+params[:member][:zip]+'%', 
                 '%'+params[:member][:email]+'%','%'+params[:member][:bill_date]+'%', @current_club,
                 last_digits,member_status]).order(:visible_id)
   end
  end

  def show
    if request.post?
      if params[:filter] == 'billing'
        search = [Settings.operation_types.enrollment_billing, Settings.operation_types.membership_billing,
                  Settings.operation_types.full_save, Settings.operation_types.change_next_bill_date,
                  Settings.operation_types.credit ]
        @operations = Operation.where(["(operation_type in(?,?,?,?,?)) AND member_id like ?",
                      search[0],search[1],search[2],search[3],search[4],'%'+@current_member.id+'%'])
      elsif params[:filter] == 'communications'
        search = [Settings.operation_types.active_email, Settings.operation_types.prebill_email,
                  Settings.operation_types.cancellation_email, Settings.operation_types.refund_email]
        @operations = Operation.where(["(operation_type in(?,?,?,?)) AND member_id like ?",
                      search[0],search[1],search[2],search[3],'%'+@current_member.id+'%'])
      elsif params[:filter] == 'profile'
        search = [Settings.operation_types.cancel, Settings.operation_types.future_cancel,
                  Settings.operation_types.save_the_sale]
        @operations = Operation.where("(operation_type in(?,?,?)) AND member_id like ?",
                      search[0],search[1],search[2],'%'+@current_member.id+'%')
      elsif params[:filter] == 'others'
        @operations = Operation.where("operation_type like ? AND member_id like ?",
                      Settings.operation_types.others,'%'+@current_member.id+'%')
      else
        @operations = @current_member.operations.all
      end
    else  
      @operations = @current_member.operations.all
    end
    @operation_filter = params[:filter]
    @notes = @current_member.member_notes.paginate(:page => params[:page], :order => "created_at DESC")
    @credit_cards = @current_member.credit_cards.all
    @active_credit_card = @current_member.active_credit_card
    @transactions = @current_member.transactions.paginate(:page => params[:page], :order => "created_at DESC")
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
        if params[:cancel_date].to_date > Date.today
          begin
            @current_member.cancel_date = params[:cancel_date]
            @current_member.save!
            message = "Member cancellation scheduled to #{params[:cancel_date]} - Reason: #{params[:reason]}"
            Auditory.audit(current_agent, @current_member, message, @current_member, Settings.operation_types.future_cancel)
            flash[:notice] = message
            redirect_to show_member_path
          rescue
            # TODO: 
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
      if params[:next_bill_date].to_date > Date.today
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
      fulfillment.update_attribute :delivered_at, DateTime.now
      message = "Resend fulfillment #{fulfillment.product}."
      Auditory.audit(@current_agent,@current_member,message,@current_member)    
      flash[:notice] = message 
      redirect_to show_member_path
    end
  end

  def add_club_cash_transaction
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
end

