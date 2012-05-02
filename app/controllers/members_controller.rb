class MembersController < ApplicationController
  before_filter :validate_club_presence
  before_filter :setup_member, :only => [ :show, :edit, :refund ]

  def index
  end

  def show
   #@operations = @member.operations.paginate(:page => params[:page], :order => "operation_date DESC")
    @operations = @member.operations.all
    @notes = @member.member_notes.paginate(:page => params[:page], :order => "created_at DESC")
    @credit_cards = @member.credit_cards.paginate(:page => params[:page], :order => "created_at DESC")
    @active_credit_card = @member.active_credit_card
    @transactions = @member.transactions.paginate(:page => params[:page], :order => "created_at DESC")
  end

  def new
    @member = Member.new 
    @terms_of_membership = TermsOfMembership.where(:club_id => @current_club )
  end

  def edit  
  end

  def refund
    @transaction = Transaction.find_by_uuid_and_member_id params[:transaction_id], @current_member.uuid
    if request.post?
      if @transaction.nil?
        flash.error = "Transaction not found."
        redirect_to member_path
      else
        answer = Transaction.refund(params[:amount], @transaction)
        if answer[:code] == "000"
          flash.notice = answer[:message]
          redirect_to member_path
        else
          flash.now.error = answer[:message]
        end
      end
    end
  end

  private
    def setup_member
      @current_member = Member.find_by_visible_id_and_club_id(params[:member_prefix], @current_club.id)
      # Sebas hay que reemplazar @memebr por @current_member y borrar la linea de abajo
      @member = Member.find_by_visible_id_and_club_id(params[:member_prefix], @current_club.id)
    end
end
