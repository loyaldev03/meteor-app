class Api::MembersController < ApplicationController

  # Method : POST
  #
  # Params:
  #  * terms_of_membership_id
  #  * member { :first_name, :last_name, :email, :address, :city, :state, :zip, :country, :phone_number }
  #  * credit_card { :expiration_month, :expiration_year, :number }
  #  * enrollment_amount
  # 
  def enroll
    response = {}
    tom = TermsOfMembership.find_by_id(params[:terms_of_membership_id])
    if tom.nil?
      response = { :message => "Terms of membership not found", :code => 401 }
    else
      club = tom.club
      credit_card = CreditCard.new params[:credit_card]
      member = Member.new params[:member]
      member.created_by_id = current_agent.id
      member.terms_of_membership = tom
      member.club = club
      if member.valid? and credit_card.valid?
        response = member.enroll(credit_card, params[:enrollment_amount], current_agent)
      else
        errors = member.errors.collect {|attr, message| "#{attr}: #{message}" }.join('\n') + 
                  credit_card.errors.collect {|attr, message| "#{attr}: #{message}" }.join('\n')
        response = { :message => "Member data is invalid: #{errors}", :code => 405 }
      end
    end

    respond_to do |format|
      format.json { render json: response }
    end    
  end

  def update_profile
    response = {}
    member = Member.find_by_visible_id_and_club_id(params[:id],params[:club_id]) 
    if member.update_attributes(params[:member]) 
      message = "Member updated successfully"
      Auditory.audit(current_agent, member, message, member)
      response = { :message => message, :code => "000", :member_id => member.id, :v_id => member.visible_id }
    else
      errors = member.errors.collect {|attr, message| "#{attr}: #{message}" }.join('\n')
      response = { :message => "Member data is invalid: #{errors}", :code => 405 }
    end

    respond_to do |format|
      format.json { render json: response }
    end
  end
end
