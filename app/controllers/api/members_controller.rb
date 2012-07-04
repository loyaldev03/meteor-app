class Api::MembersController < ApplicationController
  skip_before_filter :verify_authenticity_token

  respond_to :json

  # Terms of the membership ID that which the memeber is enrolling with.
  attr_reader :terms_of_membership_id

  # Information related the member that is submitting to enroll.
  # It has the following information:
  # {first_name, last_name, email, address, city, state, zip, country, phone_number }
  attr_reader :member

  # Member's credit card information. 
  # It has the following information:
  # { expire_month, expire_year, number }
  attr_reader :credit_card

  # Adition information submited when the member enrolls. We storage that information for further reports.
  # It has the following information:
  # { member_id, prospect_id, enrollment_amount, product_sku, product_description, mega_channel, marketing_code, fulfillment_code, ip_address, user_agent, :referral_host,
  # referral_parameters, referral_path, user_id, landing_url, terms_of_membership_id,
  # preferences, cookie_value, cookie_set, campaign_medium, campaign_description,
  # campaign_medium_version, is_joint }
  attr_reader :enrollment_info

  # Shows the method results and also informs the errors.
  attr_reader :message

  # Code related to the method result.
  attr_reader :code

  # Visible id of the member that was enrolled or recovered, or updated.
  attr_reader :v_id

  # Prospect id related to the member that was enrolled, or recoverd or updated. 
  attr_reader :prospect_id

  # ID that sends drupal.
  attr_reader :api_id

  # ID of the member.
  attr_reader :id

  # Club id that the member belongs to.
  attr_reader :club_id

  #
  attr_reader :drupal_user_id

  # Club cash information neccesary to add a club cash transaction. 
  # It has the following information:{ amount, description }
  attr_reader :club_cash_transaction

  # Method : POST
  # 
  # Recieves: 
  # * terms_of_membership_id
  # * member
  # * credit_card
  # * enrollment_info 
  # Returns: 
  # * message 
  # * code
  # * v_id 
  # * prospect_id
  #

  def enroll
    response = {}
    tom = TermsOfMembership.find_by_id(params[:terms_of_membership_id])  
    if tom.nil?
      response = { :message => "Terms of membership not found", :code => Settings.error_codes.not_found }
    else
      response = Member.enroll(tom, current_agent, (params[:enrollment_info][:enrollment_amount] if params[:enrollment_info]), params[:member], params[:credit_card], params[:setter][:cc_blank], params[:enrollment_info])
    end
    render json: response
  end

  # Method : PUT
  #
  # Recieves: 
  # * id
  # * club_id 
  # * member 
  # Returns: 
  # * message 
  # * code
  # * v_id 
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
  # * api_id
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
