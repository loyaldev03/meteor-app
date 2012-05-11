class MembersController < ApplicationController
  before_filter :validate_club_presence
  before_filter :validate_member_presence, :except => [ :index, :new ]

  def index
    if request.post?
      @members = Member.joins(:credit_cards).where([" visible_id like ? AND first_name like ? AND last_name like ? AND address like ? AND
                                 phone_number like ? AND city like ? AND state like ? AND zip like ? AND email like ? 
                                 AND bill_date like ? AND club_id like ? AND credit_cards.active = 1 AND (credit_cards.last_digits like ?
                                 OR credit_cards.last_digits is null)", 
                               '%'+params[:member][:member_id]+'%','%'+params[:member][:first_name]+'%',
                               '%'+params[:member][:last_name]+'%','%'+params[:member][:address]+'%',
                               '%'+params[:member][:phone_number]+'%','%'+params[:member][:city]+'%',
                               '%'+params[:member][:state]+'%','%'+params[:member][:zip]+'%', 
                               '%'+params[:member][:email]+'%','%'+params[:member][:bill_date]+'%', @current_club,
                               '%'+params[:member][:last_digits]+'%'])
    end
  end

  def show
    @operations = @current_member.operations.all
    @notes = @current_member.member_notes.paginate(:page => params[:page], :order => "created_at DESC")
    @credit_cards = @current_member.credit_cards.all
    @active_credit_card = @current_member.active_credit_card
    @transactions = @current_member.transactions.paginate(:page => params[:page], :order => "created_at DESC")
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
        if answer[:code] == "000"
          flash[:notice] = "Save the sale succesfully applied"
          redirect_to show_member_path
        else
          flash.now[:error] = answer[:message]
        end
      end
    end
  end

  def refund
    @transaction = Transaction.find_by_uuid_and_member_id params[:transaction_id], @current_member.uuid
    if @transaction.nil?
      flash[:error] = "Transaction not found."
      redirect_to show_member_path
      return
    end
    if request.post?
      answer = Transaction.refund(params[:refund_amount], params[:transaction_id])
      if answer[:code] == "000"
        flash[:notice] = answer[:message]
        redirect_to show_member_path
      else
        flash.now[:error] = answer[:message]
      end
    end
  end

  def full_save
    message = "Full save done"
    Auditory.audit(@current_agent, nil, message, @current_member)
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
            Auditory.audit(current_agent, @current_member, message, @current_member)
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
  end

  def change_next_bill_date
    if request.post?
      if params[:next_bill_date].to_date > Date.today
        begin
          @current_member.change_next_bill_date!(params[:next_bill_date])
          message = "Next bill date changed to #{params[:next_bill_date]}"
          Auditory.audit(current_agent, @current_member, message, @current_member)
          flash[:notice] = message
          redirect_to show_member_path
        rescue Exception => e
          flash[:error] = "Could not set the NBD on this member. #{e}"
        end
      else
        flash[:error] = "Next nill date cant be older than today or today."
      end
    end
  end
end
