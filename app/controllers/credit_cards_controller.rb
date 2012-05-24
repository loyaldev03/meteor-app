class CreditCardsController < ApplicationController
	before_filter :validate_club_presence
	before_filter :validate_member_presence
  layout '2-cols'

  def new
    @credit_card = CreditCard.new
    @actual_credit_card = @current_member.active_credit_card
  end

  def create
    credit_card = CreditCard.new(params[:credit_card])
    credit_card.member_id = @current_member.id
    actual_credit_card = @current_member.active_credit_card
    credit_card.last_digits = credit_card.number.last(4)

    respond_to do |format|
      #if credit_card.am_card.valid?
        if credit_card.save && actual_credit_card.deactivate
          message = "Credit card #{credit_card.number} added and set active."
          Auditory.audit(@current_agent, credit_card, message, @current_member)
          format.html { redirect_to show_member_path(:id => @current_member), notice: "The Credit Card #{credit_card.number} was successfully added and setted as active."  } 
        else
          flash[:error] = "Credit card is invalid or is expired!"
          format.html { render "new" } 
        end
     # else
     #   flash[:error] = "Credit card is invalid or is expired!"
      #  format.html { render "new" } 
      #end
    end
  end

  def activate
  	new_credit_card = CreditCard.find(params[:credit_card_id])
  	former_credit_card = @current_member.active_credit_card

    # TODO: do we need json format??
    # TODO: we NEED transactions!!!    
    respond_to do |format|
      if new_credit_card.activate && former_credit_card.deactivate
        message = "Credit card #{new_credit_card.number} set as active."
        Auditory.audit(@current_agent, new_credit_card, message, @current_member)
        format.html { redirect_to show_member_path(:id => @current_member), notice: "The Credit Card #{new_credit_card.number} was activated." }
      else
        format.html { redirect_to show_member_path(:id => @current_member), error: new_credit_card.errors }
      end
    end
  end

  def set_as_blacklisted
  	credit_card = CreditCard.find(params[:credit_card_id])

  	respond_to do |format|
      if credit_card.blacklist
        message = "Credit card #{credit_card.number} blacklisted."
        Auditory.audit(@current_agent, credit_card, message, @current_member)
        format.html { redirect_to show_member_path(:id => @current_member), notice: "The Credit Card #{credit_card.number} was blacklisted." }
      else
        format.html { redirect_to show_member_path(:id => @current_member), error: credit_card.errors }
      end
  	end
  end
end
