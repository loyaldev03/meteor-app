class CreditCardsController < ApplicationController
	before_filter :validate_club_presence
	before_filter :validate_member_presence
  authorize_resource :credit_card

  def new
    @credit_card = CreditCard.new
    @actual_credit_card = @current_member.active_credit_card
  end

  def create
    credit_card = CreditCard.new(params[:credit_card])
    credit_card.member_id = @current_member.id
    actual_credit_card = @current_member.active_credit_card

    if credit_card.number == actual_credit_card.number and credit_card.expire_year == actual_credit_card.expire_year and credit_card.expire_month == actual_credit_card.expire_month 
      response = { :code => Settings.error_codes.invalid_credit_card,  :message => "Credit card is already set as active." }
    else
      response = @current_member.update_credit_card_from_drupal(params[:credit_card])
    end

    if response[:code] == Settings.error_codes.success
      flash.now[:notice] = response[:message]
    else
      flash.now[:error] = "#{response[:message]} #{response[:errors].to_s}"
    end

    render "new"
  end

  def activate
  	new_credit_card = CreditCard.find(params[:credit_card_id])
  	former_credit_card = @current_member.active_credit_card

    # TODO: we NEED transactions!!!    
    if new_credit_card.activate && former_credit_card.deactivate
      message = "Credit card #{new_credit_card.last_digits} activated."
      Auditory.audit(@current_agent, new_credit_card, message, @current_member)
      redirect_to show_member_path(:id => @current_member), notice: message
    else
      redirect_to show_member_path(:id => @current_member), error: new_credit_card.errors
    end
  end

end
