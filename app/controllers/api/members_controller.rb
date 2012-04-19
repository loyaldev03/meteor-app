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
    domain = Domain.find_by_url(params[:domain_url])
    if tom.nil?
      response = { :message => "Terms of membership not found", :code => 401 }
    else
      club = tom.club
      if club.domain.url == params[:domain_url]
        # member = Member.new params[:member]
        # member.credit_cards << CreditCard.new :
        # member.created_by_id = current_agent.id
        # member.club = club
        # member.bill


        # add_operation
      else
        response = { :message => "Club not found or domain invalid", :code => 402 }
      end
    end

    respond_to do |format|
      format.json { render json: response }
    end    
  end
end
