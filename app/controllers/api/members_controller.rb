class Api::MembersController < ApplicationController

  # Method : POST
  #
  # Params:
  #  * user_id
  #  * terms_of_membership_id
  #  * domain_url
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
      # TODO: I dont know if domain_url is necesarrilly. Ask carlos!
      # domain = Domain.find_by_url(params[:domain_url])
      club = tom.club
      user = User.find_by_uuid(params[:user_id])
      if user.nil?
        user = User.new ip_address: request.env['REMOTE_ADDR'], user_agent: request.env['HTTP_USER_AGENT']
        user.domain = club.domains.first
        user.save
      end
#      if not club.domains.find_by_url(params[:domain_url]).nil? and params[:domain_url] == user.domain.url
        credit_card = CreditCard.new params[:credit_card]
        member = Member.new params[:member]
        member.credit_cards << credit_card
        member.created_by_id = current_agent.id
        member.terms_of_membership = tom
        member.club = club
        if member.valid?
          response = user.enroll(member, credit_card, params[:enrollment_amount], current_agent)
        else
          errors = member.errors.collect {|attr, message| "#{attr}: #{message}" }.join('\n')
          response = { :message => "Member data is invalid: #{errors}", :code => 405 }
        end
#      else
#        response = { :message => "Club not found or domain invalid", :code => 402 }
#      end
    end

    respond_to do |format|
      format.json { render json: response }
    end    
  end
end
