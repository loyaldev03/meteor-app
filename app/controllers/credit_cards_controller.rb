class CreditCardsController < ApplicationController
	before_filter :validate_club_presence
	before_filter :validate_member_presence
  
  def new
    @credit_card = CreditCard.new
    @actual_credit_card = @current_member.active_credit_card
  end

  def create
    credit_card = CreditCard.new(params[:credit_card])
    credit_card.member_id = @current_member.id
    actual_credit_card = @current_member.active_credit_card

    if credit_card.am_card.valid?
      if credit_card.save && actual_credit_card.deactivate
        message = "Credit card #{credit_card.last_digits} added and set active."
        Auditory.audit(@current_agent, credit_card, message, @current_member)
        redirect_to show_member_path(:id => @current_member), notice: "The Credit Card #{credit_card.last_digits} was successfully added and setted as active." 
        return
      end
    end
    flash[:error] = "Credit card is invalid or is expired!"
    render "new"
  end

  def activate
  	new_credit_card = CreditCard.find(params[:credit_card_id])
  	former_credit_card = @current_member.active_credit_card

    # TODO: we NEED transactions!!!    
    if new_credit_card.activate && former_credit_card.deactivate
      message = "Credit card #{new_credit_card.last_digits} set as active."
      Auditory.audit(@current_agent, new_credit_card, message, @current_member)
      redirect_to show_member_path(:id => @current_member), notice: "The Credit Card #{new_credit_card.last_digits} was activated."
    else
      redirect_to show_member_path(:id => @current_member), error: new_credit_card.errors
    end
  end

  def set_as_blacklisted
    credit_card = CreditCard.find(params[:credit_card_id])

    if credit_card.blacklist
      message = "Credit card #{credit_card.last_digits} blacklisted."
      Auditory.audit(@current_agent, credit_card, message, @current_member)
      redirect_to show_member_path(:id => @current_member), notice: "The Credit Card #{credit_card.last_digits} was blacklisted." 
    else
      redirect_to show_member_path(:id => @current_member), error: credit_card.errors 
  	end
  end

  def unset_blacklisted
    credit_card = CreditCard.find(params[:credit_card_id])

    authorize! :undo_credit_card_blacklist, credit_card   

    if credit_card.unset_blacklisted
      message = "Credit card #{credit_card.last_digits} was unsetted as blacklisted."
      Auditory.audit(@current_agent, credit_card, message, @current_member)
      redirect_to show_member_path(:id => @current_member), notice: "The Credit Card #{credit_card.last_digits} was unsetted as blacklisted." 
    else
      redirect_to show_member_path(:id => @current_member), error: credit_card.errors 
    end
  end

end
