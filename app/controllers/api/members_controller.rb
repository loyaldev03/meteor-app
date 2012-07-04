class Api::MembersController < ApplicationController
  skip_before_filter :verify_authenticity_token

  respond_to :json



  # Method : POST
  # 
  # Recieves: 
  # * terms_of_membership_id
  # * member: Information related to the member that is submitting to enroll.
  # * credit_card: Information related to member's credit card. 
  # * enrollment_info: Adition information submited when the member enrolls. We storage that information for further reports. 
  # Returns: 
  # * message: Shows the method results and also informs the errors.
  # * code: Code related to the method result.
  # * v_id: Visible id of the member that was enrolled or recovered, or updated.
  # * prospect_id
  #

  def enroll
    response = {}
    tom = TermsOfMembership.find_by_id(params[:terms_of_membership_id])  
    if params[:enrollment_info][:enrollment_amount]
      if tom.nil?
        response = { :message => "Terms of membership not found", :code => Settings.error_codes.not_found }
      else
        response = Member.enroll(tom, current_agent,params[:enrollment_info][:enrollment_amount], params[:member], params[:credit_card], params[:setter][:cc_blank], params[:enrollment_info])
      end
    else
      response = {:message => "Enrollment amount was not recieved.", :code => Settings.error_codes.not_found}
    end
    render json: response
  end

  # Method : PUT
  #
  # Recieves: 
  # * id: ID of the member.
  # * club_id
  # * member
  # Returns: 
  # * message: Shows the method results and also informs the errors. 
  # * code: Code related to the method result.
  # * v_id: Visible id of the member that was enrolled or recovered, or updated.
  # 
  def update_profile
    response = {}
    member = Member.find_by_visible_id_and_club_id(params[:id],params[:club_id]) 
    # member.skip_api_sync! if XXX
    member.update_attribute(:wrong_address, nil) if params[:setter][:wrong_address] == '1' unless params[:setter].nil?
    member.update_attribute(:wrong_phone_number, nil) if params[:setter][:wrong_phone_number] == '1' unless params[:setter].nil?
    if member.update_attributes(params[:member]) 
      message = "Member updated successfully"
      Auditory.audit(current_agent, member, message, member)
      response = { :message => message, :code => Settings.error_codes.success, :member_id => member.id, :v_id => member.visible_id }
    else
      response = { :message => "Member data is invalid: #{member.error_to_s}", :code => Settings.error_codes.member_data_invalid }
    end
    render json: response
  end

  # Method : GET
  #
  # Recieves:
  # * api_id: ID that sends drupal.
  # * club_id
  #
  def profile
    member = Member.find_by_api_id_and_club_id(params[:api_id],params[:club_id]) 
    if member.nil?
      render json: { code: Settings.error_codes.not_found, message: 'member not found' }
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

  # Method : POST
  #
  # Recieves:
  # * id
  # * club_id
  # * club_cash_transaction.
  # Returns:
  # * message 
  # * code
  def add_club_cash
    response = {}
    amount = params[:club_cash_transaction][:amount] || params[:amount]
    description = params[:club_cash_transaction][:description] if params[:club_cash_transaction]
    
    member = Member.find_by_visible_id_and_club_id(params[:id], params[:club_id])  
    if member.nil?
      response = { :message => "Member not found", :code => Settings.error_codes.not_found }  
    else
      response = member.add_club_cash(current_agent,amount,description)
    end
    render json: response
  end

end
