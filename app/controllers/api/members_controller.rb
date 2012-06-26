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
      response = Member.enroll(tom, current_agent, params[:enrollment_amount], params[:member], params[:credit_card],params[:setter] && params[:setter][:cc_blank])
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

  # Method : POST
  #
  # Params:
  #  * "drupal_user_id" and "domain" if its being requested from drupal.
  #  * "id" and "club_id" if its being requested from the platform. 
  #  * club_cash_transaction => { amount, description}
  # 
  def add_club_cash
    member_id = params[:drupal_user_id] || params[:id]
    club_id = params[:domain] || params[:club_id]
    response = {}

    member = Member.find_by_visible_id_and_club_id(member_id, club_id)  
    if member.nil?
      response = { :message => "Member not found", :code => Settings.error_codes.not_found }  
    else
      cct = ClubCashTransaction.new()
      cct.member_id = member
      cct.amount = params[:club_cash_transaction][:amount] || params[:amount]
      cct.description = params[:club_cash_transaction][:description] if params[:club_cash_transaction]

      if cct.save
        message = "Club cash transaction done!. Amount: $#{cct.amount}"
        Auditory.audit(current_agent, cct, message, member)
        response = { :message => message, :code => Settings.error_codes.success, :v_id => member.visible_id }
      else
        errors = cct.errors.collect {|attr, message| "#{attr}: #{message}" }.join(". ")
        message = "Could not saved club cash transactions: #{errors}"
        response = { :message => message, :code => Settings.error_codes.club_cash_transaction_not_successful, :v_id => member.visible_id  }
      end
    end
    render json: response
  end

end
