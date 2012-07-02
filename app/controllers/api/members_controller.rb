class Api::MembersController < ApplicationController
  skip_before_filter :verify_authenticity_token

  respond_to :json

  # Method : POST
  #
  # Params:
  #  * terms_of_membership_id
  #  * member { :first_name, :last_name, :email, :address, :city, :state, :zip, :country, :phone_number }
  #  * credit_card { :expire_month, :expire_year, :number }
  #  * enrollment_info {:member_id, :prospect_id, :enrollment_amount, :product_sku, :product_description, :mega_channel,
  #                     :marketing_code, :fulfillment_code, :ip_address, :user_agent, :referral_host,
  #                     :referral_parameters, :referral_path, :user_id, :landing_url, :terms_of_membership_id,
  #                     :preferences, :cookie_value, :cookie_set, :campaign_medium, :campaign_description,
  #                     :campaign_medium_version, :is_joint }
  # 

  def enroll
    response = {}
    tom = TermsOfMembership.find_by_id(params[:terms_of_membership_id])  
    if tom.nil?
      response = { :message => "Terms of membership not found", :code => Settings.error_codes.not_found }
    else
      response = Member.enroll(tom, current_agent, params[:enrollment_info][:enrollment_amount], params[:member], params[:credit_card], params[:setter][:cc_blank], params[:enrollment_info])
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
    # member.skip_api_sync! if XXX
    member.update_attribute(:wrong_address, nil) if params[:setter][:wrong_address] == '1' unless params[:setter].nil?
    member.update_attribute(:wrong_phone_number, nil) if params[:setter][:wrong_phone_number] == '1' unless params[:setter].nil?
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
  #  * club_id
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
  # Params:
  #  * "drupal_user_id" and "domain" if its being requested from drupal.
  #  * "id" and "club_id" if its being requested from the platform. 
  #  * club_cash_transaction => { amount, description}
  # 
  def add_club_cash
    response = {}
    member_id = params[:drupal_user_id] || params[:id]
    club_id = params[:domain] || params[:club_id]
    amount = params[:club_cash_transaction][:amount] || params[:amount]
    description = params[:club_cash_transaction][:description] if params[:club_cash_transaction]
    
    member = Member.find_by_visible_id_and_club_id(member_id, club_id)  
    if member.nil?
      response = { :message => "Member not found", :code => Settings.error_codes.not_found }  
    else
      response = member.add_club_cash(current_agent,amount,description)
    end
    render json: response
  end

end
