class Api::MembersController < ApplicationController
  # Method : POST
  #
  # Params:
  #  * user_id
  #  * tom_id
  #  * domain_url
  #  * member { :first_name, :last_name .... }
  #  * credit_card { :expiration_month .... }
  #  * enrollment amount
  # 
  def enroll
    response = {}
    tom = TermsOfMembership.find_by_id(params[:tom_id])
    if tom.nil?
      response = { :message => "Terms of membership not found", :code => 401 }
    else
      domain = Domain.find_by_url(params[:domain_url])
      club = tom.club
      if club.domain.url == params[:domain_url]
        user = User.find(params[:user_id])
        if user.nil?
          response = { :message => "User not found", :code => 403 }
        else
          credit_card = CreditCard.new params[:credit_card]
          member = Member.new params[:member]
          member.credit_cards << credit_card
          member.created_by_id = current_agent.id
          member.club = club
          if member.valid?
            response = user.enroll(member, credit_card, params[:enrollment_amount])
          else
            errors = member.errors.collect {|attr, message| "#{attr}: #{message}" }.join('\n')
            response = { :message => "Member data is invalid: #{errors}", :code => 405 }
          end
        end
      else
        response = { :message => "Club not found or domain invalid", :code => 402 }
      end
    end

    respond_to do |format|
      format.json { render json: response }
    end    
  end
end
