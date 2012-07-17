class Api::MembersController < ApplicationController
  skip_before_filter :verify_authenticity_token

  respond_to :json

  # Method : POST
  #
  # Submits a member to be created. THis method will call the method enroll on member model. It will validate
  # the member's data (including its credit card) and, in case it is correct, it will create and save the member.
  # It will also send a welcome email and charge the enrollment to the member's credit card.  
  #
  # [current_agent] The agent's ID that will be enrolling the member.
  #
  # [member] Information related to the member that is sumbitting the enroll. Here is a list of the regex we are using to validate {Member show}.
  #             *first_name: The first name of the member that is enrolling. We are not accepting any invalid character (like: #$"!#%&%").
  #             *last_name: The last name of the member that is enrolling. We are not accepting any invalid character (like: #$"!#%&%"). 
  #             *address: The address of the member that is being enrolled.
  #             *city: City from where the member is from.
  #             *state: State from where the member is from. At the moment we are not using any kind of code.
  #             *zip: Member's address's zip code. We are accepting only formats like: xxxxx or xxxxx-xxxx. Only numbers.
  #             *country: The country standard code where the member is from. This code has a length of 2 digits. (Eg: US for United States).
  #             *phone_number: The member's personal phone number. We are accepting only numbers, dashes, 'x','int' and '+'. We recommend frontend
  #              to validate numbers with the following formats: +xx xxxx-xxxx(xxxx), xxx xxx xxxx (intxx) or xxx-xxx-xxxx x123.
  #             *email: Members personal email. This mail will be one of our contact method and every mail will be send to this. We recommend frontend to
  #              validate mails with the following formts like: xxxxxxxxx@xxxx.xxx.xx or xxxxxx+xxx@xxxx.xxx.xx
  #             *terms_of_memberhips_id: This is the id of the term of membership the member is enrolling with. With this param
  #              we will set some features such as provisional days or amount of club cash the member will start with. It is present at member level. 
  #             *enrollment_amount: Amount of money that takes to enroll. It is present at member level.
  #             *joint: It shows if it is set as type joint. It is use to see if at the end of the contract we have with the partner, we share the member's 
  #              informatión with him. joint=1 means we will share this informatión. If this value is null, we will automaticaly set it as 0. This is an exclusive value, 
  #              it can be seted using 1 or 0, or true or false. It is present at member level.
  #             *birth_date: Birth date of the member. This date is stored with format "yyyy-mm-dd"
  #             *credit_card  [Hash]
  #             *enrollment_info  [Hash]
  # [credit_card] Information related to member's credit card. {CreditCard show}
  #                 *number: Number of member's credit card, from where we will charge the membership or any other service.  
  #                  This number will be stored as a hashed value. This number can have white-spaces or not ()
  #                 *expire_month: The month (in numbers) in which the credit card will expire. Eg. For june it would be 6. 
  #                 *expire_year: The year (in numbers) in which the credit card will expire.  
  # [enrollment_info] Aditional information submited when the member enrolls. We storage that information for further reports. 
  #                     *prospect_id: Id of the prospect the enrollment info is related to.
  #                     *product_sku: Freeform text that is representative of the SKU.
  #                     *product_description: Description of the selected product.
  #                     *mega_channel: 
  #                     *marketing_code: multi-team
  #                     *fulfillment_code: Id of the fulfillment we are sending to our member. (car-flag).
  #                     *ip_address: Ip address from where the enrollment is being submitted.
  #                     *user_agent: Information related to the browser and computer from where the enrollment is being submitted.
  #                     *referral_host:  Link where is being redirect when after subimiting the enroll. (It shows the params in it).
  #                     *referral_parameters
  #                     *referral_path
  #                     *user_id: User ID alias UID is an md5 hash of the user's IP address and user-agent information.
  #                     *landing_url: Url from where te submit comes from.
  #                     *preferences: Information about the preferences selected when enrolling. This will be use to know about the member likes.
  #                      This information is selected by the member. 
  #                     *cookie_value: Cookie from where the enrollment is being submitted.
  #                     *cookie_set: If the cookie_value is being recieved or not. It also informs if the client has setted a cookie on his side.
  #                     *campaign_medium
  #                     *campaign_description: The name of the campaign.
  #                     *campaign_medium_version
  #                     *joint: It shows if it is set as type joint. It is use to see if at the end of the contract we have with the partner, we share the member's 
  #                      informatión with him. joint=1 means we will share this informatión. If this value is null, we will automaticaly set it as 0. This is an exclusive value, 
  #                      it can be seted using 1 or 0, or true or false. It is present at member level.
  # [setter] Variable used to pass some boolean values as "cc_blank" for enrolling, or "wrong_address" for update.
  #           * cc_blank: Boolean variable which will tell us to allow or not enrolling a member with a blank credit card. It should only be true
  #                       when we are allowing a credit blank credit card. If this variable is true, it should be pass a credit_card with the following 
  #                       attributes: number=>"0000000000" and expire_month and expired_year setted as today's month and year respectively.
  #
  # [message] Shows the method results and also informs the errors.
  # [code] Code related to the method result.
  # [member_id] ID of the member. This ID is unique for each member. (32 characters string). This value is used by platform. API users dont know the member id at this moment.
  # [v_id] Visible id of the member that was enrolled or recovered, or updated.
  # [member_errors] A hash with members errors. This will be use to show errors on members creation page.
  # [credit_card_errors] A hash with credit card errors. This will be use to show errors on members creation page.
  #
  # @param [Hash] member
  # @param [Hash] setter
  # @return [String] *message*
  # @return [Integer] *code*
  # @return [Integer] *member_id*
  # @return [Integer] *v_id*
  # @return [Hash] *member_errors*
  # @return [Hash] *credit_card_errors*
  # 
  def create
    response = {}
    tom = TermsOfMembership.find_by_id(params[:member][:terms_of_membership_id])  
    if tom.nil?
      response = { :message => "Terms of membership not found", :code => Settings.error_codes.not_found }
    else
      response = Member.enroll(
        tom, 
        current_agent, 
        params[:member][:enrollment_amount], 
        params[:member], 
        params[:member][:credit_card], 
        params[:setter] && params[:setter][:cc_blank], 
        params[:member][:enrollment_info]
      )
    end
    render json: response 
  end

  # Method : PUT
  # Updates member's data.
  # [member_id] ID of the member. This ID is unique for each member. (32 characters string). This value is used by platform. API users dont know the member id at this moment.
  # [member] Information related to the member that is being updated.. Here is a list of the regex we are using to validate. {Member show}.
  #             *first_name: The first name of the member that is enrolling. We are not accepting any invalid character (like: #$"!#%&%").
  #             *last_name: The last name of the member that is enrolling. We are not accepting any invalid character (like: #$"!#%&%"). 
  #             *address: The address of the member that is being enrolled. 
  #             *city: City from where the member is from.
  #             *state: State from where the member is from. At the moment we are not using any kind of code.
  #             *zip: Member's address's zip code. We are accepting only formats like: xxxxx or xxxxx-xxxx. Only numbers.
  #             *country: The country standard code where the member is from. This code has a length of 2 digits. (Eg: US for United States).
  #             *phone_number: The member's personal phone number. We are accepting numbers with the following formats: xxx-xxx-xxxx, xxxx-xxxx(xxxx), 
  #              +xx xxxx-xxxx(xxxx), xxx xxx xxxx (intxx) or xxx-xxx-xxxx x123. Only numbers.
  #             *email: Members personal email. This mail will be one of our contact method and every mail will be send to this. We are accepting
  #              mails with the following formats: xxxxxxxxx@xxxx.xxx.xx or xxxxxx+xxx@xxxx.xxx.xx
  # [setter] Variable used to pass some boolean values as "cc_blank" for enrolling or "wrong_address" for update.
  #           * wrong_address: Boolean value that (if it is true) it will tell us to unset member's addres as wrong. (It will set wrong_address as nil)
  #           * wrong_phone_number: Boolean value that (if it is true) it will tell us to unset member's phone_number as wrong. (It will set 
  #                                 wrong_phone_number as nil)
  #
  # [message] Shows the method results and also informs the errors.
  # [code] Code related to the method result.
  # [v_id] Visible id of the member that was updated.
  # [errors] A hash with members errors. This will be use to show errors on members edit page. 
  #
  # @param [String] id
  # @param [Hash] member
  # @param [Hash] setter
  # @return [String] *message*
  # @return [Integer] *member_id*  
  # @return [Integer] *code*
  # @return [Integer] *v_id*
  # @return [Hash] *errors*
  # 
  def update
    response = {}
    member = Member.find(params[:id])
    # member.skip_api_sync! if XXX
    member.update_attribute(:wrong_address, nil) if params[:setter][:wrong_address] == '1' unless params[:setter].nil?
    member.update_attribute(:wrong_phone_number, nil) if params[:setter][:wrong_phone_number] == '1' unless params[:setter].nil?
    if member.update_attributes(params[:member]) 
      message = "Member updated successfully"
      Auditory.audit(current_agent, member, message, member)
      response = { :message => message, :code => Settings.error_codes.success, :member_id => member.id}
    else
      response = { :message => "Member data is invalid.", :code => Settings.error_codes.member_data_invalid, :errors => member.errors }
    end
    render json: response
  end

  # Method : GET
  # Returns information related to member and its credit card.
  #
  # [id] Members ID. This id is a string type ID (lenght 32 characters.). This ID is unique for each member.
  # [member] Information related to the member that is sumbitting the enroll. Here is a list of the regex we are using to validate {Member show}.
  #             *first_name: The first name of the member that is enrolling. We are not accepting any invalid character (like: #$"!#%&%").
  #             *last_name: The last name of the member that is enrolling. We are not accepting any invalid character (like: #$"!#%&%").
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
  # @param [String] *id*
  # @return [String] *message* 
  # @return [Hash] *member*: Information of member's profile.
  # @return [Hash] *credit_card*: Information of member's credit card.
  # @return [Integer] *code*: Code related to the method result.
  #
  def shows
    member = Member.find(params[:id])
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


end
