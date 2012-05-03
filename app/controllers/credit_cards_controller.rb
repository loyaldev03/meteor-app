class CreditCardsController < ApplicationController
	before_filter :validate_club_presence
	before_filter :validate_member_presence
  layout '2-cols'

  def new
  end

  def add
  	@new_credit_card = CreditCard.new(params[:credit_card])
  	@actual_credit_card = @current_member.active_credit_card
  end

  def activate
  	new_credit_card = CreditCard.find(params[:id])
  	actual_credit_card = @current_member.active_credit_card

    respond_to do |format|
      if new_credit_card.update_attributes(:active => 1) && actual_credit_card.update_attributes(:active => 0)
        format.html { redirect_to member_path(:id => @current_member), notice: "The credit_card was activated." }
        format.json { head :no_content }
      else
        format.html { redirect_to member_path(:id => @current_member), error: @credit_card.errors }
        format.json { render json: @credit_card.errors, status: :unprocessable_entity }
      end
    end
  end

  def set_as_blacklisted
  	credit_card = CreditCard.find(params[:id])

  	respond_to do |format|
      if credit_card.update_attributes(:blacklisted => true)
        format.html { redirect_to member_path(:id => @current_member), notice: "The credit_card was blacklisted." }
        format.json { head :no_content }
      else
        format.html { redirect_to member_path(:id => @current_member), error: @credit_card.errors }
        format.json { render json: @credit_card.errors, status: :unprocessable_entity }
  	end
  end

end
