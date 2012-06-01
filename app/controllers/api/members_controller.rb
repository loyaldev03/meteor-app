class Api::MembersController < ApplicationController
  skip_before_filter :verify_authenticity_token

  respond_to :json

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
end
