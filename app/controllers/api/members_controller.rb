class Api::MembersController < ApplicationController
  skip_before_filter :verify_authenticity_token

  respond_to :json

  # Method : POST
  #
  # Params:
  #  * terms_of_membership_id
  #  * member { :first_name, :last_name, :email, :address, :city, :state, :zip, :country, :phone_number }
  #  * credit_card { :expire_month, :expire_year, :number }
  #  * enrollment_amount
  # 
  def enroll
    response = {}
    tom = TermsOfMembership.find_by_id(params[:terms_of_membership_id])
    if tom.nil?
      response = { :message => "Terms of membership not found", :code => Settings.error_codes.not_found }
    else
      response = Member.enroll(tom, current_agent, params[:enrollment_amount], params[:member], params[:credit_card])
    end
    render json: response
  end


  # Method : PUT
  #
  # Params:
  #  * id
  #  * club_id
  #  * member { :first_name, :last_name, :email, :address, :city, :state, :zip, :phone_number }
  # 
  def update_profile
    response = {}
    member = Member.find_by_visible_id_and_club_id(params[:id],params[:club_id]) 
    
      member.update_attribute(:wrong_address, nil) if params[:setter][:wrong_address] == '1' 
      member.update_attribute(:wrong_phone_number, nil) if params[:setter][:wrong_phone_number] == '1'
    if member.update_attributes(params[:member]) 
      message = "Member updated successfully"
      Auditory.audit(current_agent, member, message, member)
      response = { :message => message, :code => Settings.error_codes.success, :member_id => member.id, :v_id => member.visible_id }
    else
      errors = member.errors.collect {|attr, message| "#{attr}: #{message}" }.join("\n")
      response = { :message => "Member data is invalid: #{errors}", :code => Settings.error_codes.member_data_invalid }
    end
    render json: response
  end


  # Method : GET
  #
  # Params:
  #  * api_id
  # 
  def profile
    # TODO: improve this Member find method
    member = Member.find_by_api_id(params[:api_id]) 
    if member.nil?
      render json: { code: '9345', message: 'member not found' }
    else
      render json: { 
        code: '000', 
        member: {
          first_name: member.first_name, last_name: member.last_name, email: member.email,
          address: member.address, city: member.city, state: member.state, zip: member.zip,
          phone_number: member.phone_number
        }, 
        credit_card: {
          expire_month: member.active_credit_card.expire_month,
          expire_year: member.active_credit_card.expire_year
        } 
      }
    end
  end    
end
