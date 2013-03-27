class Api::MembersController < ApplicationController
  skip_before_filter :verify_authenticity_token
  respond_to :json

  ##
  # Submits a member to be created. This method will call the method enroll on member model. It will validate
  # the member's data (including its credit card) and, in case it is correct, it will create and save the member.
  # It will also send a welcome email and charge the enrollment to the member's credit card.  
  #
  # @resource /api/v1/members
  # @action POST
  #
  # @required [String] api_key Agent's authentication token. This token allows us to check if the agent is allowed to request this action.
  # @required [Hash] member Information related to the member that is sumbitting the enroll. It also contains information related to the enrollment (this will be stored as enrollment_info). It must have the following information:
  #   <ul>
  #     <li><strong>first_name</strong> The first name of the member that is enrolling. We are not accepting any invalid character (like: #$"!#%&%"). </li>
  #     <li><strong>last_name</strong> The last name of the member that is enrolling. We are not accepting any invalid character (like: #$"!#%&%"). </li>
  #     <li><strong>address</strong> The address of the member that is being enrolled. </li>
  #     <li><strong>city</strong> City from where the member is from. </li>
  #     <li><strong>state</strong> The state standard code where the member is from. </li>
  #     <li><strong>zip</strong> Member's address's zip code. We are accpeting only formats like: xxxxx or xxxxx-xxxx for US. Only numbers. In case the member is from Canada, we accept canadian zips with the valid format (LNL NLN or LNLNLN where 'L' stands for letters and 'N' for numbers.) </li>
  #     <li><strong>country</strong> The country standard code where the member is from. This code has a length of 2 digits. (Eg: US for United States). </li>
  #     <li><strong>phone_country_code</strong> First field of the phone number. This is the number related to the country the phone number is from. (Eg. For United States it would be "1"). </li>
  #     <li><strong>phone_area_code</strong> Second field of the phone number. This is the number related to the area the phone number is from. </li>
  #     <li><strong>phone_local_number</strong> Third and last field of the phone_number. This is the local number where the member will be reached.</li>
  #     <li><strong>email</strong> Members personal email. This mail will be one of our contact method and every mail will be send to this. We recommend frontend to validate mails with the following formts like: xxxxxxxxx@xxxx.xxx.xx or xxxxxx+xxx@xxxx.xxx.xx </li>
  #     <li><strong>gender</strong> Gender of the member. The values we are recieving are "M" for male or "F" for female. [optional]</li>
  #     <li><strong>type_of_phone_number</strong> Type of the phone number the member has input (home, mobile, others). [optional]</li>
  #     <li><strong>external_id</strong> Member's id related to an external platform that we don't administrate. [optional]</li>
  #     <li><strong>terms_of_memberhips_id</strong> This is the id of the term of membership the member is enrolling with. With this param we will set some features such as provisional days or amount of club cash the member will start with. It is present at member level.  </li>
  #     <li><strong>enrollment_amount</strong> Amount of money that takes to enroll. It is present at member level.</li>
  #     <li><strong>birth_date</strong> Birth date of the member. This date is stored with format "yyyy-mm-dd" [optional]</li>
  #     <li><strong>prospect_id</strong> Id of the prospect the enrollment info is related to.</li>
  #     <li><strong>product_sku</strong> Freeform text that is representative of the SKU. This will be passed with format string, each product separated with ',' (comma). (Example: "kit-card,circlet") [optional] </li>
  #     <li><strong>product_description</strong> Description of the selected product. [optional]</li>
  #     <li><strong>mega_channel</strong> [optional] </li>
  #     <li><strong>marketing_code</strong> multi-team [optional] </li>
  #     <li><strong>fulfillment_code</strong> Id of the fulfillment we are sending to our member. (car-flag). [optional]</li>
  #     <li><strong>ip_address</strong> Ip address from where the enrollment is being submitted. [optional] </li>
  #     <li><strong>user_agent</strong> Information related to the browser and computer from where the enrollment is being submitted. [optional] </li>
  #     <li><strong>referral_host</strong> Link where is being redirect when after subimiting the enroll. (It shows the params in it). [optional]</li>
  #     <li><strong>referral_parameters</strong>  [optional]</li>
  #     <li><strong>referral_path</strong> [optional]</li>
  #     <li><strong>user_id</strong> User ID alias UID is an md5 hash of the user's IP address and user-agent information. [optional]</li>
  #     <li><strong>landing_url</strong> Url from where te submit comes from. [optional]</li>
  #     <li><strong>preferences</strong> Information about the preferences selected when enrolling. This will be use to know about the member likes. This information is selected by the member. This information is stored with format as hash encoded with json. [optional] </li>
  #     <li><strong>cookie_value</strong> Cookie from where the enrollment is being submitted.[optional]</li>
  #     <li><strong>cookie_set</strong> If the cookie_value is being recieved or not. It also informs if the client has setted a cookie on his side. [optional]</li>
  #     <li><strong>campaign_medium</strong> [optional]</li>
  #     <li><strong>campaign_description</strong> The name of the campaign. [optional]</li>
  #     <li><strong>campaign_medium_version</strong> [optional]</li>
  #     <li><strong>joint</strong> It shows if it is set as type joint. It is use to see if at the end of the contract we have with the partner, we share the member's informatión with him. joint=1 means we will share this informatión. If it is null, we will automaticaly set it as 0. This is an exclusive value, it can be seted using 1 or 0, or true or false. It is present at member level.  [optional]</li>
  #     <li><strong>credit_card</strong> Hash with credit cards information. It must have the following information:</li>
  #     <ul>
  #       <li><strong>number</strong> Number of member's credit card, from where we will charge the membership or any other service. This value won't be save, but instead we will save a token obtained from the payment gateway. (We accept numbers and characters like "-", whitespaces and "/") </li>
  #       <li><strong>expire_month</strong> The month (in numbers) in which the credit card will expire. Eg. For june it would be 6. </li>
  #       <li><strong>expire_year</strong> The year (in numbers) in which the credit card will expire.  </li>
  #     </ul>
  #   </ul>
  # @optional [Hash] setter Variable used to pass some boolean values as "cc_blank". It must have the following information:
  #   <ul>
  #     <li><strong>cc_blank</strong> Boolean variable which will tell us to allow or not enrolling a member with a blank credit card. If it is true, send credit_card with the following attributes: number=>"0000000000" and expire_month and expired_year setted as today's month and year respectively. </li>
  #     <li><strong>skip_api_sync</strong> Boolean variable which tell us if we have to sync or not user to remote api (e.g drupal) [optional]</li>
  #   </ul>
  #
  # @example_request 
  #   ```json
  #   {
  #     "api_key":"aq4BS8XzbTvczcDZvDRt",
  #     "member": {
  #       "first_name":"Alice",
  #       "last_name":"Brennan",
  #       "address":"SomeSt",
  #       "state":"Deirdre",
  #       "city":"City",
  #       "zip":12345,
  #       "country":"US",
  #       "phone_country_code":1,
  #       "phone_area_code":123,
  #       "phone_local_number":1234,
  #       "email":"alice@brennan.com",
  #       "gender":"M",
  #       "type_of_phone_number":"home",
  #       "terms_of_memberhips_id":10,
  #       "enrollment_amount":34.34,
  #       "birth_date":"1989",
  #       "prospect_id":"",
  #       "product_sku":"KIT-CARD",
  #       "product_description":"product default",
  #       "external_id":"2568",
  #       "preferences":{ "color":"red", "player":"DaveJr" },
  #       "credit_card":{
  #          "number":"4485-6302-0286-9418"
  #          "expire_month":5
  #          "expire_year":2016
  #       }
  #     }
  #   }
  #   ```
  # @example_request_description Requesting enroll of a valid member.
  # @example_response 
  #   ```json
  #   {
  #     "result": {
  #       "message":"Member enrolled successfully $34.34 on TOM(10) -test-",
  #       "code":"000",
  #       "member_id":"123458",
  #       "autologin_url":""
  #     }
  #   }
  #   ```
  # @example_response_description Response in case it was success.
  #
  # @example_request 
  #   ```json
  #   {
  #     "api_key":"aq4BS8XzbTvczcDZvDRt",
  #     "member": {
  #       "first_name":"Alice",
  #       "last_name":"Brennan",
  #       "address":"SomeSt",
  #       "state":"Deirdre",
  #       "city":"City",
  #       "zip":12345,
  #       "country":"United States",
  #       "phone_country_code":1,
  #       "phone_area_code":123,
  #       "phone_local_number":1234,
  #       "email":"alice@brennan.com",
  #       "gender":"M",
  #       "type_of_phone_number":"home",
  #       "terms_of_memberhips_id":10,
  #       "enrollment_amount":34.34,
  #       "birth_date":"1989",
  #       "prospect_id":"",
  #       "product_sku":"KIT-CARD",
  #       "product_description":"product default",
  #       "external_id":"2568",
  #       "preferences":{ "color":"red", "player":"DaveJr" },
  #       "credit_card":{
  #          "number":"4485-6302-0286-9418"
  #          "expire_month":5
  #          "expire_year":2016
  #       },
  #       "setter":{
  #          "cc_blank":0,
  #          "skip_api_sync":0
  #       }
  #     }
  #   }
  #   ```
  # @example_request_description Requesting enroll with invalid information.
  # @example_response 
  #   ```json
  #   {
  #     "result": {
  #       "message":"Member iformation is invalid.",
  #       "code":"405",
  #       "errors":{"country":["is the wrong length (should be 2 characters)","is not included in the list"]}
  #     }
  #   }
  #   ```
  # @example_response_description Response with member's errors within an 'error' hash.
  #
  # @response_field [String] message Shows the method results and also informs the errors.
  # @response_field [Integer] code Code related to the method result.
  # @response_field [Integer] member_id Member's id. Integer autoincrement value that is used by platform. This value will be returned only if the member is enrolled successfully.
  # @response_field [Hash] errors A hash with members and credit card errors. This will be use to show errors on members creation page.
  # @response_field [String] autologin_url Url provided by Drupal, used to autologin a member into it. This URL is used by campaigns in order to redirect members to their drupal account.
  #
  def create
    tom = TermsOfMembership.find(params[:member][:terms_of_membership_id])  
    my_authorize! :api_enroll, Member, tom.club_id
    render json: Member.enroll(
      tom, 
      current_agent, 
      params[:member][:enrollment_amount], 
      params[:member], 
      params[:member][:credit_card], 
      params[:setter] && params[:setter][:cc_blank].to_s.to_bool, 
      params[:setter] && params[:setter][:skip_api_sync].to_s.to_bool
    )
  rescue ActiveRecord::RecordNotFound
    render json: { :message => "Terms of membership not found", :code => Settings.error_codes.not_found }
  end

  ##
  # Updates member's data.
  #
  # @resource /api/v1/members/:id
  # @action PUT
  #
  # @required [String] api_key Agent's authentication token. This token allows us to check if the agent is allowed to request this action.
  # @required [Integer] id Member's id. Integer autoincrement value that is used by platform. Have in mind this is part of the url.
  # @required [Hash] member Information related to the member that is sumbitting the enroll. It also contains information related to the enrollment (this will be stored as enrollment_info). It must have the following information: 
  #   <ul>
  #     <li><strong>first_name</strong> The first name of the member that is enrolling. We are not accepting any invalid character (like: #$"!#%&%"). </li>
  #     <li><strong>last_name</strong> The last name of the member that is enrolling. We are not accepting any invalid character (like: #$"!#%&%"). </li>
  #     <li><strong>address</strong> The address of the member that is being enrolled. </li>
  #     <li><strong>city</strong> City from where the member is from.</li>
  #     <li><strong>state</strong> The state standard code where the member is from. </li>
  #     <li><strong>zip</strong> Member's address's zip code. We are accpeting only formats like: xxxxx or xxxxx-xxxx for US. Only numbers. In case the member is from Canada, we accept canadian zips with the valid format (LNL NLN or LNLNLN where 'L' stands for letters and 'N' for numbers.)</li>
  #     <li><strong>country</strong> The country standard code where the member is from. This code has a length of 2 digits. (Eg: US for United States).</li>
  #     <li><strong>phone_country_code</strong> First field of the phone number. This is the number related to the country the phone number is from. (Eg. For United States it would be "1"). </li>
  #     <li><strong>phone_area_code</strong> Second field of the phone number. This is the number related to the area the phone number is from. </li>
  #     <li><strong>phone_local_number</strong> Third and last field of the phone_number. This is the local number where the member will be reached.</li>
  #     <li><strong>email</strong> Members personal email. This mail will be one of our contact method and every mail will be send to this. We recommend frontend to validate mails with the following formts like: xxxxxxxxx@xxxx.xxx.xx or xxxxxx+xxx@xxxx.xxx.xx </li>
  #     <li><strong>gender</strong> Gender of the member. The values we are recieving are "M" for male or "F" for female. [optional]</li>
  #     <li><strong>type_of_phone_number</strong> Type of the phone number the member has input (home, mobile, others). [optional] </li>
  #     <li><strong>birth_date</strong> Birth date of the member. This date is stored with format "yyyy-mm-dd" [optional]</li>
  #     <li><strong>member_group_type_id</strong> Id of the member's group type where he belongs to. Each club can has many classifications for its member's, like 'VIP' or 'Celebrity'.</li>
  #     <li><strong>external_id</strong> Member's id related to an external platform that we don't administrate. [optional]</li>
  #     <li><strong>api_id</strong> Send this value with the User Id of your site. This id is used to access your API (e.g. Autologin URL - Update member data). [optional]</li>
  #     <li><strong>credit_card</strong> Hash with credit cards information. It must have the following information:</li>
  #     <ul>
  #       <li><strong>number</strong> Number of member's credit card, from where we will charge the membership or any other service. This value won't be save, but instead we will save a token obtained from the payment gateway. (We accept numbers and characters like "-", whitespaces and "/") </li>
  #       <li><strong>expire_month</strong> The month (in numbers) in which the credit card will expire. Eg. For june it would be 6. </li>
  #       <li><strong>expire_year</strong> The year (in numbers) in which the credit card will expire.  </li>
  #     </ul>
  #   </ul>
  # @required [Hash] setter Variable used to pass some boolean values as "wron_phone_number". It must have the following information:
  #   <ul>
  #     <li><strong>wrong_phone_number</strong> Boolean value that (if it is true) it will tell us to unset member's phone_number as wrong. (It will set wrong_phone_number as nil) [optional]</li>
  #     <li><strong>batch_update</strong> Boolean variable which tell us if this update was made by a member or by a system. Send 1 if you want batch_update otherwise dont send this attribute (different operations will be stored) [optional]</li>
  #     <li><strong>skip_api_sync</strong> Boolean variable which tell us if we have to sync or not user to remote api. Send 1 if you want to skip sync otherwise dont send this attribute. [optional] (e.g drupal)</li>
  #   </ul>
  # @example_request 
  #   ```json
  #   {
  #     "api_key":"aq4BS8XzbTvczcDZvDRt",
  #     "member": {
  #       "first_name":"Alice",
  #       "last_name":"Brennan",
  #       "address":"SomeSt",
  #       "state":"Deirdre",
  #       "city":"City",
  #       "zip":12345,
  #       "country":"US",
  #       "phone_country_code":1,
  #       "phone_area_code":123,
  #       "phone_local_number":1234,
  #       "email":"alice@brennan.com",
  #       "gender":"M",
  #       "type_of_phone_number":"home",
  #       "terms_of_memberhips_id":10,
  #       "enrollment_amount":34.34,
  #       "birth_date":"1989",
  #       "prospect_id":"",
  #       "member_group_type_id":1,
  #       "product_sku":"KIT-CARD",
  #       "product_description":"product default",
  #       "external_id":"2568"
  #     },
  #       "setter":{
  #          "wrong_phone_number":0,
  #          "skip_api_sync":0,
  #          "batch_update":0
  #       }
  #   }
  #   ```
  # @example_request_description Requesting update with valid information.
  # @example_response 
  #   ```json
  #   {
  #     "result": {
  #       "message":"Member updated successfully",
  #       "code":"000",
  #       "member_id":12345
  #     }
  #   }
  #   ```
  # @example_response_description Response in case it was success.
  #
  # @example_request 
  #   ```json
  #   {
  #     "api_key":"aq4BS8XzbTvczcDZvDRt",
  #     "member": {
  #       "first_name":"Alice",
  #       "last_name":"Brennan",
  #       "address":"SomeSt",
  #       "state":"Deirdre",
  #       "city":"City",
  #       "zip":12345,
  #       "country":"US",
  #       "phone_country_code":1,
  #       "phone_area_code":123,
  #       "phone_local_number":1234,
  #       "email":"alice@brennan.com",
  #       "gender":"M",
  #       "type_of_phone_number":"home",
  #       "terms_of_memberhips_id":10,
  #       "enrollment_amount":34.34,
  #       "birth_date":"1989",
  #       "prospect_id":"",
  #       "member_group_type_id":1,
  #       "product_sku":"KIT-CARD",
  #       "product_description":"product default",
  #       "external_id":"2568"
  #     },
  #       "setter":{
  #          "wrong_phone_number":0,
  #          "skip_api_sync":0,
  #          "batch_update":0
  #       }
  #   }
  #   ```
  # @example_request_description Requesting enroll with invalid information.
  # @example_response 
  #   ```json
  #   {
  #     "result": {
  #       "message":"Member iformation is invalid.",
  #       "code":"405",
  #       "errors":{"country":["is the wrong length (should be 2 characters)","is not included in the list"]}
  #     }
  #   }
  #   ```
  # @example_response_description Response with member's errors within an 'error' hash.
  #
  # @response_field [String] message Shows the method results and also informs the errors.
  # @response_field [Integer] code Code related to the method result.
  # @response_field [Integer] member_id Member's id. Integer autoincrement value that is used by platform. It will be returned only when the request was a success.
  # @response_field [Hash] errors A hash with members errors. This will be use to show errors on members edit page. 
  # 
  def update
    response = {}
    batch_update = params[:setter] && params[:setter][:batch_update] && params[:setter][:batch_update].to_s.to_bool

    member = Member.find(params[:id])
    my_authorize! :api_update, Member, member.club_id
    member.skip_api_sync! if params[:setter] && params[:setter][:skip_api_sync] && params[:setter][:skip_api_sync].to_s.to_bool
    member.api_id = params[:member][:api_id] if params[:member][:api_id].present? and batch_update
    member.wrong_phone_number = nil if params[:setter][:wrong_phone_number].to_s.to_bool unless params[:setter].nil?
    member.wrong_phone_number = nil if (member.phone_country_code != params[:member][:phone_country_code].to_i || 
                                                          member.phone_area_code != params[:member][:phone_area_code].to_i ||
                                                          member.phone_local_number != params[:member][:phone_local_number].to_i)

    response = member.update_credit_card_from_drupal(params[:member][:credit_card], @current_agent)

    if response[:code] == Settings.error_codes.success
      member.update_member_data_by_params(params[:member])
      if member.save
        message = "Member updated successfully"
        Auditory.audit(current_agent, member, message, member, Settings.operation_types.profile_updated) unless batch_update
        response = { :message => message, :code => Settings.error_codes.success, :member_id => member.id}
      else
        message = "Member could not be updated, #{member.error_to_s}"
        if batch_update
          logger.error "Remote batch update message: #{message}"
        else
          Auditory.audit(current_agent, member, message, member, Settings.operation_types.profile_update_error)
        end
        response = { :message => I18n.t('error_messages.member_data_invalid'), :code => Settings.error_codes.member_data_invalid, :errors => member.errors }
      end
    end
    render json: response
  rescue ActiveRecord::RecordNotFound
    render json: { :message => "Member not found", :code => Settings.error_codes.not_found }
  end

  # Method : GET
  # Returns information related to member and its credit card.
  #
  # [url] /api/v1/members/:id
  # [api_key] Agent's authentication token. This token allows us to check if the agent is allowed to request this action.
  # [id] Members ID. This id is a string type ID (lenght 32 characters.). This ID is unique for each member.
  #      Have in mind that this value is part of the url.
  # [member] Information related to the member that is sumbitting the enroll. Here is a list of the regex we are using to validate {Member show}.
  #             *first_name: The first name of the member that is enrolling. We are not accepting any invalid character (like: #$"!#%&%").
  #             *last_name: The last name of the member that is enrolling. We are not accepting any invalid character (like: #$"!#%&%").
  #             *address: The address of the member that is being enrolled. 
  #             *city: City from where the member is from.
  #             *state: The state standard code where the member is from.
  #             *zip: Member's address's zip code. We are accpeting only formats like: xxxxx or xxxxx-xxxx for US. Only numbers. In case the member is from Canada, we accept canadian zips with the valid format (LNL NLN or LNLNLN where 'L' stands for letters and 'N' for numbers.)
  #             *phone_country_code: First field of the phone number. This is the number related to the country the phone number is from. (Eg. For United States it would be "011"). 
  #             *phone_area_code: Second field of the phone number. This is the number related to the area the phone number is from. 
  #             *phone_local_number: Third and last field of the phone_number. This is the local number where the member will be reached.
  #             *email: Members personal email. This mail will be one of our contact method and every mail will be send to this. We are accepting
  #              mails with formtas like: xxxxxxxxx@xxxx.xxx.xx or xxxxxx+xxx@xxxx.xxx.xx
  #             *club_cash_amount: Amount of the club cash the member has at this moment. We accept a maximun of two digits after the comma.
  #             *club_cash_expire_date: Date when the club cash will be expired and set to 0. This date is saved as date format.
  #             *gender: Gender of the member. The values we are recieving are "M" for male or "F" for female.
  #             *bill_date: Date when the billing will be done. 
  #             *next_retry_bill_date: Date when the billing will be done. 
  #             *wrong_address: Reason the member was set as undeliverable. 
  #             *wrong_phone_number: Reason the member was set as unreachable. 
  #             *member_since_date: Date when the member was created. This date is saved with date format.
  #             *reactivation_times: Integer value that tells us how many times this member was recovered. 
  #             *blacklisted: Boolean value that says if the member is blacklisted or not (true = blacklisted, false = not blacklisted)
  #             *member_group_type_id: Group type the member belongs to.
  #             *recycled_times: 
  #             *preferences: Information about the preferences selected when enrolling. This will be use to know about the member likes.
  #             *sync_status: String with status of the actual synchronization status with drupal. This value will be only returned if member's club api type is 'Drupal::Member'
  #                           *Options: 
  #                                   *'synced': Member is synced with drupal successfully. 
  #                                   *'not_synced': Member is not synced with drupal. 
  #                                   *'with_errors': Member is not synced with drupal because there were errors.
  #             *last_synced_at: Date of the last time the member was synchronized against drupal. It is saved with dateTime format. This value will be only returned if member's club api type is 'Drupal::Member'
  #             *last_sync_error_at: Date of the last time there was an error while trying to synchronized with drupal. It is saved with dateTime format. This value will be only returned if member's club api type is 'Drupal::Member'
  #             *last_sync_error: Last error message while syncrhonizating. This value will be only returned if member's club api type is 'Drupal::Member'
  # [credit_card] Information related to member's credit card.
  #                 *expire_month: The month (in numbers) in which the credit card will expire. Eg. For june it would be 6. 
  #                 *expire_year: The year (in numbers) in which the credit card will expire.  
  # [current_membership] Information related to the member's membership at the moment.
  #                 *status: Member's current status.  
  #                 *join_date: Date when the member join. This date is updated each time the member is recovered, or it is saved the sale.
  #                 *cancel_date: Date schedule when the member will be canceled. 
  #                 *quota: 
  #                 *terms_of_membership: [Hash]
  # [terms_of_membership] Information related to the terms of membership the membership is related to.
  #                 *name: Terms of membership name.  
  #                 *description: Description of the terms of membership.
  #                 *provisional_days: Days given before the first billing is done.
  #                 *mode: 
  #                 *needs_enrollment_approval: 
  #                 *installment_amount: 
  #                 *installment_type: 
  #                 *club_cash_amount: 
  # [enrollment_info] Information obtained from the member's enrollment
  #              *enrollment_amount: Amount of money that takes to enroll. It is present at member level
  #              *product_sku: Freeform text that is representative of the SKU. This will be passed with format string, each product separated with ',' (comma). (Example: "kit-card,circlet")
  #              *product_description: Description of the selected product.
  #              *mega_channel: 
  #              *marketing_code: multi-team
  #              *fulfillment_code: Id of the fulfillment we are sending to our member. (car-flag).
  #              *ip_address: Ip address from where the enrollment is being submitted.
  #              *user_agent: Information related to the browser and computer from where the enrollment is being submitted.
  #              *referral_host:  Link where is being redirect when after subimiting the enroll. (It shows the params in it).
  #              *referral_parameters
  #              *referral_path 
  #              *user_id: User ID alias UID is an md5 hash of the user's IP address and user-agent information.
  #              *landing_url: Url from where te submit comes from.
  #              *preferences: Information about the preferences selected when enrolling. This will be use to know about the member likes.
  #               this information is selected by the member. This information is stored with format as hash encoded with json.
  #              *cookie_value: Cookie from where the enrollment is being submitted.
  #              *cookie_set: If the cookie_value is being recieved or not. It also informs if the client has setted a cookie on his side.
  #              *campaign_medium
  #              *campaign_description: The name of the campaign.
  #              *campaign_medium_version
  #              *joint: It shows if it is set as type joint. It is use to see if at the end of the contract we have with the partner, we share the member's 
  #               informatión with him. joint=1 means we will share this informatión. If it is null, we will automaticaly set it as 0. 
  #               This is an exclusive value, it can be seted using 1 or 0, or true or false. It is present at member level.
  #              *prospect_id: Id of the prospect related to this member. 
  # [message] Shows the method errors. This message will be only shown when there was an error.
  # [code] Code related to the method result.
  # [message] Shows the method errors. This message will be only shown when there was an error.
  #
  # @param [String] api_key
  # @return [String] *message* 
  # @return [Hash] *member*
  # @return [Hash] *credit_card*
  # @return [Hash] *current_membership*
  # @return [Hash] *enrollment_info*
  # @return [Integer] *code*
  #
  def show
    member = Member.find(params[:id])
    my_authorize! :api_profile, Member, member.club_id
    club = member.club
    membership = member.current_membership
    terms_of_membership = membership.terms_of_membership
    ei = member.enrollment_infos[0]
    ei = if ei.blank? 
      {} 
    else
      ei.attributes.symbolize_keys.slice(
        :enrollment_amount, 
        :product_sku, 
        :product_description, 
        :mega_channel, 
        :marketing_code, 
        :fulfillment_code, 
        :ip_address, 
        :user_agent, 
        :referral_host, 
        :referral_parameters, 
        :referral_path, 
        :user_id, 
        :landing_url, 
        :cookie_value, 
        :cookie_set, 
        :campaign_medium, 
        :campaign_description,
        :campaign_medium_version, 
        :joint, 
        :prospect_id
      )
    end
    render json: {
      code: Settings.error_codes.success,
      member: {
        first_name: member.first_name, 
        last_name: member.last_name, 
        email: member.email,
        address: member.address, 
        city: member.city, 
        state: member.state, 
        zip: member.zip,
        birth_date: member.birth_date,
        phone_country_code: member.phone_country_code, 
        phone_area_code: member.phone_area_code,
        phone_local_number: member.phone_local_number, 
        type_of_phone_number: member.type_of_phone_number,
        club_cash_amount: member.club_cash_amount,
        club_cash_expire_date: member.club_cash_expire_date,
        gender: member.gender,
        bill_date: member.bill_date,
        next_retry_bill_date: member.next_retry_bill_date,
        wrong_address: member.wrong_address,
        wrong_phone_number: member.wrong_phone_number,
        member_since_date: member.member_since_date,
        reactivation_times: member.reactivation_times,
        blacklisted: member.blacklisted,
        member_group_type_id: member.member_group_type.name,
        recycled_times: member.recycled_times,
        preferences: member.preferences,
      }.merge(club.api_type == 'Drupal::Member' ? {} : {sync_status: member.sync_status, 
                                                        last_synced_at: member.last_synced_at,
                                                        last_sync_error_at: member.last_sync_error_at,
                                                        last_sync_error: member.last_sync_error
                                                       }),
      credit_card: {
        expire_month: (member.active_credit_card && member.active_credit_card.expire_month),
        expire_year: (member.active_credit_card && member.active_credit_card.expire_year)
      },
      current_membership:{
        status: membership.status,
        join_date: membership.join_date,
        cancel_date: membership.cancel_date,
        quota: membership.quota,
        terms_of_membership:{
          name: terms_of_membership.name,
          description: terms_of_membership.description,
          provisional_days: terms_of_membership.provisional_days,
          mode: terms_of_membership.mode,
          needs_enrollment_approval: terms_of_membership.needs_enrollment_approval,
          installment_amount: terms_of_membership.installment_amount,
          installment_type: terms_of_membership.installment_type,
          club_cash_amount: terms_of_membership.club_cash_amount
        }
      },
      enrollment_info: ei
    }
  rescue ActiveRecord::RecordNotFound
    render json: { code: Settings.error_codes.not_found, message: 'Member not found' }
  end    

  ##
  # Updates member's club cash's data.
  #
  # @resource /api/v1/members/:id/club_cash
  # @action PUT
  #
  # @required [String] api_key Agent's authentication token. This token allows us to check if the agent is allowed to request this action.
  # @required [Integer] id Member's id. Integer autoincrement value that is used by platform. Have in mind this is part of the url.
  # @required [Float] amount club cash amount to be set on this member profile. We only accept numbers with up to two digits after the comma.
  # @required [String] expire_date club cash expiration date. This date is stored with datetime format.
  # @response_field [String] message Shows the method results and also informs the errors.
  # @response_field [Integer] code Code related to the method result.
  # @response_field [Integer] member_id Member's id. Integer autoincrement value that is used by platform. It will be returned only when the request was a success.
  # 
  def club_cash
    member = Member.find(params[:id])
    my_authorize! :api_update_club_cash, Member, member.club_id
    response = { :message => "This club is not allowed to fix the amount of the club cash on members.", :code => Settings.error_codes.club_cash_cant_be_fixed, :member_id => member.id }
    unless member.club.club_cash_transactions_enabled
      member.skip_api_sync!
      member.club_cash_amount = params[:amount]
      member.club_cash_expire_date = params[:expire_date]
      member.save(:validate => false)
      message = "Member updated successfully"
      Auditory.audit(current_agent, member, message, member, Settings.operation_types.profile_updated)
      response = { :message => message, :code => Settings.error_codes.success, :member_id => member.id }
    end
    render json: response
  rescue ActiveRecord::RecordNotFound
    render json: { :message => "Member not found", :code => Settings.error_codes.not_found }
  end


  # Method : PUT
  # Updates member's next retry bill date.
  #
  # [url] api/v1/members/:member_id/next_bill_date
  # [api_key] Agent's authentication token. This token allows us to check if the agent is allowed to request this action. 
  # [member_id] Members ID. This id is a string type ID (lenght 32 characters.). This ID is unique for each member.
  #             Have in mind that this value is part of the url.
  # [next_bill_date] Date to be stored as date where we should bill this member. This date is stored with date format. (required)
  #
  # [message] Shows the method result.
  # [code] Code related to the method result.
  # [errors] A hash with members and next_bill_date errors. This will be use to show errors on members edit page. 
  #
  # @param [String] api_key
  # @param [String] next_bill_date
  # @return [String] *message*
  # @return [String] *errors*  
  # @return [Integer] *code*
  # 
  def next_bill_date
    member = Member.find params[:member_id]
    my_authorize! :api_change_next_bill_date, Member, member.club_id
    render json: member.change_next_bill_date(params[:next_bill_date], @current_agent)
    
    rescue ActiveRecord::RecordNotFound
      render json: { :message => "Member not found", :code => Settings.error_codes.not_found }
  end 


  # Method : GET
  # Gets an array with the member's uuid that were updated between the dates given. 
  #
  # [url] api/v1/members/report/find_all_by_updated/:start_date/:end_date
  # [api_key] Agent's authentication token. This token allows us to check if the agent is allowed to request this action. 
  # [member_id] Members ID. This id is a string type ID (lenght 32 characters.). This ID is unique for each member.
  #             Have in mind that this value is part of the url.
  # [start_date] Date where we will start the query from. This date must be in datetime format. Have in mind that this value is part of the url. (required)
  # [end_date] Date where we will end the query. This date must be in datetime format. Have in mind that this value is part of the url. (required)
  #
  # [message] Shows the method result. This message will be shown when there is an error.
  # [list] Hash with member's uuid updated between the dates given. This list will be returned only when this method is success.
  # [code] Code related to the method result.
  #
  # @param [String] api_key
  # @param [String] start_date
  # @param [String] end_date
  # @return [String] *message*
  # @return [Integer] *code*
  # @return [Hash] *list*
  # 
  def find_all_by_updated
    my_authorize! :api_find_all_by_updated, Member
    if params[:start_date].blank? or params[:end_date].blank?
      answer = { :message => "Dates must not be null or blank", :code => Settings.error_codes.wrong_data }
    else
      members_list = ( Member.where :updated_at =>(params[:start_date].to_datetime)..(params[:end_date].to_datetime) ).collect &:uuid
      answer = { :list => members_list, :code => Settings.error_codes.success }
    end
    render json: answer
    rescue ArgumentError => e
      render json: { :message => "Wrong date format", :code => Settings.error_codes.wrong_data }
  end


  # Method : GET
  # Gets an array with the member's uuid that were created between the dates given. 
  #
  # [url] api/v1/members/report/find_all_by_created/:start_date/:end_date
  # [api_key] Agent's authentication token. This token allows us to check if the agent is allowed to request this action. 
  # [member_id] Members ID. This id is a string type ID (lenght 32 characters.). This ID is unique for each member.
  #             Have in mind that this value is part of the url.
  # [start_date] Date where we will start the query from. This date must be in datetime format. Have in mind that this value is part of the url. (required)
  # [end_date] Date where we will end the query. This date must be in datetime format. Have in mind that this value is part of the url. (required)
  #
  # [message] Shows the method result. This message will be shown when there is an error.
  # [list] Hash with member's uuid created between the dates given. This list will be returned only when this method is success.
  # [code] Code related to the method result.
  #
  # @param [String] api_key
  # @param [String] start_date
  # @param [String] end_date
  # @return [String] *message*
  # @return [Integer] *code*
  # @return [Hash] *list*
  # 
  def find_all_by_created
    my_authorize! :api_find_all_by_created, Member
    if params[:start_date].blank? or params[:end_date].blank?
      answer = { :message => "Dates must not be null or blank", :code => Settings.error_codes.wrong_data }
    else
      members_list = ( Member.where :created_at =>(params[:start_date].to_datetime)..(params[:end_date].to_datetime) ).collect &:uuid
      answer = { :list => members_list, :code => Settings.error_codes.success }
    end
    render json: answer
    rescue ArgumentError => e
      render json: { :message => "Wrong date format", :code => Settings.error_codes.wrong_data }
  end


end