class CreditCardsController < ApplicationController
	before_filter :validate_club_presence
	before_filter :validate_member_presence
  layout '2-cols'

  def new
    @new_credit_card = CreditCard.new
    @actual_credit_card = @current_member.active_credit_card
  end

  def create
    @credit_card = CreditCard.new(params[:credit_card])
    @credit_card.member_id = @current_member.id
    @actual_credit_card = @current_member.active_credit_card

  	respond_to do |format|
      if @credit_card.save && @actual_credit_card.update_attributes(:active => 0)
        format.html { redirect_to show_member_path(:id => @current_member), notice: "The Credit Card was successfully created." }
        format.json { render json: @credit_card, status: :created, location: @credit_Card }
      else
        format.html { render action: "new" }
        format.json { render json: @credit_card.errors, status: :unprocessable_entity }
      end
    end
  end

  def activate
  	new_credit_card = CreditCard.find(params[:credit_card_id])
  	actual_credit_card = @current_member.active_credit_card

    respond_to do |format|
      if new_credit_card.update_attributes(:active => true) && actual_credit_card.update_attributes(:active => 0)
        format.html { redirect_to show_member_path(:id => @current_member), notice: "The credit_card was activated." }
        format.json { head :no_content }
      else
        format.html { redirect_to show_member_path(:id => @current_member), error: @credit_card.errors }
        format.json { render json: @credit_card.errors, status: :unprocessable_entity }
      end
    end
  end

  def set_as_blacklisted
  	credit_card = CreditCard.find(params[:credit_card_id])

  	respond_to do |format|
      if credit_card.update_attributes(:blacklisted => true)
        format.html { redirect_to show_member_path(:id => @current_member), notice: "The credit_card was blacklisted." }
        format.json { head :no_content }
      else
        format.html { redirect_to show_member_path(:id => @current_member), error: @credit_card.errors }
        format.json { render json: @credit_card.errors, status: :unprocessable_entity }
      end
  	end
  end

end
