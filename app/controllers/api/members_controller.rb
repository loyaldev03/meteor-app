class Api::MembersController < ApplicationController
  skip_before_filter :verify_authenticity_token

  respond_to :json

  def create
    response = {}
    response = enroll(params[:terms_of_membership_id], current_agent,params[:enrollment_info][:enrollment_amount], params[:member], params[:credit_card], params[:enrollment_info], params[:setter][:cc_blank])
    render json: response
  end

  # Method : POST
  #
  # Submits a member to be enrolled  
  #
  # [member] Information related to the member that is sumbitting the enroll. Here is a list of the regex we are using to alidate {Member show}.
  #             *first_name: The first name of the member that is enrolling. We are not accepting any invalid character.
  #             *last_name: The last name of the member that is enrolling. We are not accepting any invalid character. 
  #             *address: The address of the member that is being enrolled. 
  #             *city: City from where the member is from.
  #             *state: State from where the member is from. At the moment we are not using any kind of code.
  #             *zip: Member's address's zip code. We are accpeting only formats like: xxxxx or xxxxx-xxxx. Only numbers.
  #             *country: The country standard code where the member is from. This code has a length of 2 digits. (Eg: US for United States).
  #             *phone_number: The member's personal phone number. We are accepting numbers with format like: xxx-xxx-xxxx, xxxx-xxxx(xxxx), 
  #              +xx xxxx-xxxx(xxxx), xxx xxx xxxx (intxx) or xxx-xxx-xxxx x123. Only numbers.
  #             *email: Members personal email. This mail will be one of our contact method and every mail will be send to this. We are accepting
  #              mails with formtas like: xxxxxxxxx@xxxx.xxx.xx or xxxxxx+xxx@xxxx.xxx.xx
  #             *terms_of_memberhips_id: This is the id of the term of membership the member is enrolling with. With this param
  #              we will set some features such as trial days or amount of club cash the memeber will start with. For more information 
  # [credit_card] Information related to member's credit card. {CreditCard show}
  #                 *number: Number of member's credit card, from where we will charge the membership or any other service.  
  #                  This number will be stored as a hashed value.
  #                 *expire_month: The month (in numbers) in which the credit card will expire. Eg. For june it would be 6. 
  #                 *expire_year: The year (in numbers) in which the credit card will expire.  
  # [enrollment_info] Adition information submited when the member enrolls. We storage that information for further reports. 
  #                     *member_id: Id of the member the enrollment info is related to. (It is setted after creating the member)
  #                     *prospect_id: Id of the prospect the enrollment info is related to.
  #                     *enrollment_amount: Amount of money that takes to enroll or recover.
  #                     *product_sku: Name of the selected product.
  #                     *product_description: Description of the selected product.
  #                     *mega_chanel: 
  #                     *marketing_code: multi-team
  #                     *fulfillment_code: Id of the fulfillment we are sending to our member. (car-flag).
  #                     *ip_address: Ip address from where the enrollment is being submitted.
  #                     *user_agent: Information related to the browser and computer from where the enrollment is being submitted.
  #                     *referral_host:  Link where is being redirect when after subimiting the enroll. (It shows the params in it).
  #                     *referral_parameters
  #                     *referral_path
  #                     *user_id
  #                     *landing_url: Url from where te submit comes from.
  #                     *terms_of_membership_id: This is the id of the term of membership the member is enrolling with. With this param
  #                      we will set some features such as trial days or amount of club cash the memeber will start with. For more information 
  #                     *preferences: Information about the preferences selected when enrolling. This will be use to know about the member likes.
  #                      This information is selected by the member. 
  #                     *cookie_value: Cookie from where the enrollment is being submitted.
  #                     *cookie_set: If the cookie_value is being recieved or not. It also inform is the client has setted a cookie on his side.
  #                     *campaign_medium
  #                     *campaign_description: The name of the campaign.
  #                     *campaign_medium_version
  #                     *is_joint
  #
  # [message] Shows the method results and also informs the errors.
  # [code] Code related to the method result.
  # [v_id] Visible id of the member that was enrolled or recovered, or updated.
  # [prospect_id] ID of the prospect (if its known).
  #
  # @param [Integer] terms_of_membership_id
  # @param [Hash] member
  # @param [Hash] credit_card
  # @param [Hash] enrollment_info
  # @return [String] *message*
  # @return [Integer] *code*
  # @return [Integer] *v_id*
  # @return [String] *prospect_id*
  # tom, current_agent,params[:enrollment_info][:enrollment_amount], params[:member], params[:credit_card], params[:enrollment_info], params[:setter][:cc_blank]
  def enroll(tom, current_agent, amount, member_params, credit_card_params, enrollment_info_params, cc_blank_params)
    tom = TermsOfMembership.find_by_id(params[:terms_of_membership_id])  
    if tom.nil?
      return { :message => "Terms of membership not found", :code => Settings.error_codes.not_found }
    else
      return Member.enroll(tom, current_agent, amount, member_params, credit_card_params, cc_blank_params, enrollment_info_params)
    end    
  end

  # Method : PUT
  # Updates a member data.
  # [id] ID of the member inside the club. This id is an integer value. The visible_id unique for each member (inside an specific club).
  # [club_id] Id of the club the member belongs to. This club id is setted at the moment of enrolling according to the terms of membership that the member selected on enrollment.
  # [member] Information related to the member that is being updated.. Here is a list of the regex we are using to alidate {Member show}.
  #             *first_name: The first name of the member that is enrolling. We are not accepting any invalid character.
  #             *last_name: The last name of the member that is enrolling. We are not accepting any invalid character. 
  #             *address: The address of the member that is being enrolled. 
  #             *city: City from where the member is from.
  #             *state: State from where the member is from. At the moment we are not using any kind of code.
  #             *zip: Member's address's zip code. We are accpeting only formats like: xxxxx or xxxxx-xxxx. Only numbers.
  #             *country: The country standard code where the member is from. This code has a length of 2 digits. (Eg: US for United States).
  #             *phone_number: The member's personal phone number. We are accepting numbers with format like: xxx-xxx-xxxx, xxxx-xxxx(xxxx), 
  #              +xx xxxx-xxxx(xxxx), xxx xxx xxxx (intxx) or xxx-xxx-xxxx x123. Only numbers.
  #             *email: Members personal email. This mail will be one of our contact method and every mail will be send to this. We are accepting
  #              mails with formtas like: xxxxxxxxx@xxxx.xxx.xx or xxxxxx+xxx@xxxx.xxx.xx
  # [message] Shows the method results and also informs the errors.
  # [code] Code related to the method result.
  # [v_id] Visible id of the member that was enrolled or recovered, or updated.
  #
  # @param [Integer] id
  # @param [Integer] club_id
  # @param [Hash] member
  # @return [String] *message*
  # @return [Integer] *code*
  # @return [Integer] *v_id*
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
  # Returns information related to member and its credit card.
  #
  # [api_id] This api_id is the same shared with drupal. This id is an integer value. The api_id unique for each member (inside an specific club). 
  # [club_id] Id of the club the member belongs to. This club id is setted at the moment of enrolling according to the terms of membership that the member selected on enrollment.
  # [member] Information related to the member that is sumbitting the enroll. Here is a list of the regex we are using to alidate {Member show}.
  #             *first_name: The first name of the member that is enrolling. We are not accepting any invalid character.
  #             *last_name: The last name of the member that is enrolling. We are not accepting any invalid character. 
  #             *address: The address of the member that is being enrolled. 
  #             *city: City from where the member is from.
  #             *state: State from where the member is from. At the moment we are not using any kind of code.
  #             *zip: Member's address's zip code. We are accpeting only formats like: xxxxx or xxxxx-xxxx. Only numbers.
  #             *phone_number: The member's personal phone number. We are accepting numbers with format like: xxx-xxx-xxxx, xxxx-xxxx(xxxx), 
  #              +xx xxxx-xxxx(xxxx), xxx xxx xxxx (intxx) or xxx-xxx-xxxx x123. Only numbers.
  #             *email: Members personal email. This mail will be one of our contact method and every mail will be send to this. We are accepting
  #              mails with formtas like: xxxxxxxxx@xxxx.xxx.xx or xxxxxx+xxx@xxxx.xxx.xx
  # [credit_card] Information related to member's credit card.
  #                 *expire_month: The month (in numbers) in which the credit card will expire. Eg. For june it would be 6. 
  #                 *expire_year: The year (in numbers) in which the credit card will expire.  
  # [message] Shows the method results and also informs the errors.
  # [code] Code related to the method result.
  #
  # @param [Integer] api_id
  # @param [Integer] club_id.
  # @return [Hash] *member*: Information of member profile.
  # @return [Hash] *credit_card*: Information of member's credit card.
  # @return [Integer] *code*: Code related to the method result.
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
  # This method adds an specific amount of cash, as club cash to the member.
  #
  # [id] ID of the member inside the club. This id is an integer value. With this value and the club id we can search for the memeber.
  # [club_id] Id of the club the member belongs to. This club id is setted at the moment of enrolling according to the terms of membership that the member selected on enrollment.
  # [club_cash_transaction] Amount of club cash that is going to be added to the member. This value has to be an integer (without decimals).
  # [message] Shows the method results and also informs the errors.
  # [code] Code related to the method result.
  #
  # @param [Integer] id
  # @param [Integer] club_id.
  # @param [Hash] club_cash_transaction
  # @return [String] *message*
  # @return [Integer] *code*
  #
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
