class MembersController < ApplicationController
  before_filter :validate_club_presence
  before_filter :validate_member_presence, :only => [ :show, :edit, :refund ]

  def index
  end

  def show
    #@operations = @current_member.operations.paginate(:page => params[:page], :order => "operation_date DESC")
    @operations = @current_member.operations.all
    @notes = @current_member.member_notes.paginate(:page => params[:page], :order => "created_at DESC")
    #@credit_cards = @current_member.credit_cards.paginate(:page => params[:page], :order => "created_at DESC")
    @credit_cards = @current_member.credit_cards.all
    @active_credit_card = @current_member.active_credit_card
    @transactions = @current_member.transactions.paginate(:page => params[:page], :order => "created_at DESC")
  end

  def new
    @current_member = Member.new 
    @terms_of_membership = TermsOfMembership.where(:club_id => @current_club )
  end

  def edit  
  end

  def save_the_sale
    if request.post?
      if TermsOfMembership.find_by_id_and_club_id(params[:new_terms_of_membership], @current_club.id).nil?
        flash[:error] = "Terms of membership not found"
        redirect_to show_member_path
      else
        answer = @member.save_the_sale(params[:new_terms_of_membership])
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
end
