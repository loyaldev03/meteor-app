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
  #     <li><strong>first_name</strong> The first name of the member that is enrolling. </li>
  #     <li><strong>last_name</strong> The last name of the member that is enrolling. </li>
  #     <li><strong>address</strong> The address of the member that is being enrolled. </li>
  #     <li><strong>city</strong> City from where the member is from. </li>
  #     <li><strong>state</strong> The state standard code where the member is from. </li>
  #     <li><strong>zip</strong> Member's address's zip code. We are accpeting only formats like: xxxxx or xxxxx-xxxx for US. Only numbers. In case the member is from Canada, we accept canadian zips with the valid format (LNL NLN or LNLNLN where 'L' stands for letters and 'N' for numbers.) </li>
  #     <li><strong>country</strong> The country standard code where the member is from. This code has a length of 2 digits. (Eg: US for United States). </li>
  #     <li><strong>phone_country_code</strong> First field of the phone number. This is the number related to the country the phone number is from. (Eg. For United States it would be "1"). </li>
  #     <li><strong>phone_area_code</strong> Second field of the phone number. This is the number related to the area the phone number is from. </li>
  #     <li><strong>phone_local_number</strong> Third and last field of the phone_number. This is the local number where the member will be reached. </li>
  #     <li><strong>email</strong> Members personal email. This mail will be one of our contact method and every mail will be send to this. We recommend frontend to validate mails with the following formts like: xxxxxxxxx@xxxx.xxx.xx or xxxxxx+xxx@xxxx.xxx.xx </li>
  #     <li><strong>gender</strong> Gender of the member. The values we are recieving are "M" for male or "F" for female. [optional] </li>
  #     <li><strong>type_of_phone_number</strong> Type of the phone number the member has input (home, mobile, others). [optional] </li>
  #     <li><strong>external_id</strong> Member's id related to an external platform that we don't administrate. [optional] </li>
  #     <li><strong>terms_of_memberhips_id</strong> This is the id of the term of membership the member is enrolling with. With this param we will set some features such as provisional days or amount of club cash the member will start with. It is present at member level.  </li>
  #     <li><strong>enrollment_amount</strong> Amount of money that takes to enroll. It is present at member level. </li>
  #     <li><strong>birth_date</strong> Birth date of the member. This date is stored with format "yyyy-mm-dd" [optional] </li>
  #     <li><strong>prospect_id</strong> Id of the prospect the enrollment info is related to. [optional] </li>
  #     <li><strong>product_sku</strong> Freeform text that is representative of the SKU. This will be passed with format string, each product separated with ',' (comma). (Example: "kit-card,circlet") </li>
  #     <li><strong>product_description</strong> Description of the selected product. [optional]</li>
  #     <li><strong>mega_channel</strong> [optional] </li>
  #     <li><strong>marketing_code</strong> multi-team [optional] </li>
  #     <li><strong>fulfillment_code</strong> Id of the fulfillment we are sending to our member. (car-flag). [optional]</li>
  #     <li><strong>ip_address</strong> Ip address from where the enrollment is being submitted. [optional] </li>
  #     <li><strong>user_agent</strong> Information related to the browser and computer from where the enrollment is being submitted. [optional] </li>
  #     <li><strong>referral_host</strong> Link where is being redirect when after subimiting the enroll. (It shows the params in it). [optional]</li>
  #     <li><strong>referral_parameters</strong> [optional]</li>
  #     <li><strong>referral_path</strong> [optional]</li>
  #     <li><strong>user_id</strong> User ID alias UID is an md5 hash of the user's IP address and user-agent information. [optional]</li>
  #     <li><strong>landing_url</strong> Url from where the submit comes from. [optional]</li>
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
  #       <li><strong>expire_year</strong> The year (in numbers) in which the credit card will expire. Have in mind it is the complete year with four digits (Eg. 2014) </li>
  #     </ul>
  #   </ul>
  # @optional [Hash] setter Variable used to pass some boolean values as "cc_blank". It must have the following information:
  #   <ul>
  #     <li><strong>cc_blank</strong> Boolean variable which will tell us to allow or not enrolling a member with a blank credit card. If it is true, send credit_card with the following attributes: number=>"0000000000" and expire_month and expired_year setted as today's month and year respectively. </li>
  #     <li><strong>skip_api_sync</strong> Boolean variable which tell us if we have to sync or not user to remote api (e.g drupal). If this value is true, we will skip the synchronization. (1=true, 0=false) [optional]</li>
  #   </ul>
  #
  # @example_request
  #   curl -v -k -X POST --data-ascii "{\"member\":{\"first_name\":\"alice\",\"last_name\":\"brennan\", \"address\":\"SomeSt\",\"city\":\"Dresden\",\"state\":\"AL\",\"gender\":\"\",\"zip\":\"12345\",\"phone_country_code\":\"1\",\"phone_area_code\":\"123\",\"phone_local_number\":\"1123\",\"birth_date\":\"1989-09-03\",\"email\":\"alice@brennan.com\",\"country\":\"US\",\"prospect_id\":\"deadbeef\", \"enrollment_amount\":\"0.0\",\"terms_of_membership_id\":\"1\",\"credit_card\":{\"number\":\"371449635398431\",\"expire_month\":\"2\",\"expire_year\":\"2014\"},\"product_sku\":\"KIT-CARD\",\"landing_url\":\"http://www.google.com\",\"mega_channel\":\"super channel\",\"marketing_code\":\"marketing code\",\"fulfillment_code\":\"1\",\"ip_address\":\"192.168.1.1\",\"user_agent\":\"Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537...\"},\"api_key\":\"o6ESwPCNtsMkJnDLzvpC\"}" -H "Content-Type: application/json" https://dev.stoneacrehq.com:3000/api/v1/members
  # @example_request_description Requesting enroll of a valid member, with params in json format.
  #
  # @example_response 
  #   {"message":"Member enrolled successfully $0.0 on TOM(1) -test2-","code":"000","member_id":11349950166,"autologin_url":""}
  # @example_response_description Example response to a valid request
  #
  # @example_request
  #   curl -v -k -X POST --data-ascii "{\"member\":{\"first_name\":\"\",\"last_name\":\"\", \"address\":\"\",\"city\":\"\",\"state\":\"\",\"gender\":\"\",\"zip\":\"\",\"phone_country_code\":\"\",\"phone_area_code\":\"\",\"phone_local_number\":\"\",\"birth_date\":\"1989-09-03\",\"email\":\"alice@brennan.com\",\"country\":\"US\",\"prospect_id\":\"\", \"enrollment_amount\":\"0.0\",\"terms_of_membership_id\":\"1\",\"product_sku\":\"KIT-CARD\",\"landing_url\":\"http://www.google.com\",\"mega_channel\":\"super channel\",\"marketing_code\":\"marketing code\",\"fulfillment_code\":\"1\",\"ip_address\":\"192.168.1.1\",\"user_agent\":\"Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537...\"},\"api_key\":\"DyqgeuHrxmb9QA8gsU22\"}" -H "Content-Type: application/json" https://dev.stoneacrehq.com:3000/api/v1/members
  # @example_request_description Requesting enroll sending some params as blank
  #
  # @example_response 
  #   {"message":"Member information is invalid.","code":"405","errors":{"phone_country_code":["can't be blank","is not a number","is too short (minimum is 1 characters)"],"phone_area_code":["can't be blank","is not a number","is too short (minimum is 1 characters)"],"phone_local_number":["can't be blank","is not a number","is too short (minimum is 1 characters)"],"first_name":["can't be blank","is invalid"],"last_name":["can't be blank","is invalid"],"address":["is invalid"],"state":["can't be blank","is invalid"],"city":["can't be blank","is invalid"],"zip":["can't be blank","The zip code is not valid for the selected country."],"credit_card":{"number":["is required"],"expire_month":["is required"],"expire_year":["is required"]}}}
  # @example_response_description Example response to a request we are sending params as blank. (Params sent as blank: first_name, last_name, address, city, state, gender, zip, phone_country_code, phone_area_code, phone_local_number and credit_card's information) 
  #
  # @response_field [String] message Shows the method results and also informs the errors.
  # @response_field [String] code Code related to the method result.
  # @response_field [Integer] member_id Member's id. Integer autoincrement value that is used by platform. This value will be returned only if the member is enrolled successfully.
  # @response_field [Hash] errors A hash with members and credit card errors.
  #   <ul>
  #     <li> <strong>key</strong> member's field name with error. (Eg: first_name, last_name, etc.). In the particular case that one or more of credit_card's field are wrong, the key will be "credit_card", and the value will be a hash that follows the same logic as this error hash. (Eg: "credit_card":{"number":["is required"],"expire_month":["is required"],"expire_year":["is required"]})  </li>
  #     <li> <strong>value</strong> Array of strings with errors. (Eg: ["can't be blank","is invalid"]). </li>
  #   </ul>
  #
  # @response_field [String] autologin_url Url provided by Drupal, used to autologin a member into it. This URL is used by campaigns in order to redirect members to their drupal account. This value wll be returned as blank in case the club is not related to drupal.
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
  rescue NoMethodError => e
    render json: { :message => "There are some params missing. Please check them.", :code => Settings.error_codes.wrong_data }
  end

  ##
  # Updates member's data. You may only send fields that has change only. In case a credit_card field has been change, make sure to send all credit cards fields again (even the ones that has not change). 
  #
  # @resource /api/v1/members/:id
  # @action PUT
  #
  # @required [String] api_key Agent's authentication token. This token allows us to check if the agent is allowed to request this action.
  # @required [Integer] id Member's ID. Integer autoincrement value that is used by platform. Have in mind this is part of the url.
  # @required [Hash] member Information related to the member that is sumbitting the enroll. It also contains information related to the enrollment (this will be stored as enrollment_info). 
  #   <ul>
  #     <li><strong>first_name</strong> The first name of the member that is enrolling. [optional] </li>
  #     <li><strong>last_name</strong> The last name of the member that is enrolling. [optional] </li>
  #     <li><strong>address</strong> The address of the member that is being enrolled. [optional] </li>
  #     <li><strong>city</strong> City from where the member is from. [optional]</li>
  #     <li><strong>state</strong> The state standard code where the member is from. [optional]</li>
  #     <li><strong>zip</strong> Member's address's zip code. We are accpeting only formats like: xxxxx or xxxxx-xxxx for US. Only numbers. In case the member is from Canada, we accept canadian zips with the valid format (LNL NLN or LNLNLN where 'L' stands for letters and 'N' for numbers.) [optional] </li>
  #     <li><strong>country</strong> The country standard code where the member is from. This code has a length of 2 digits. (Eg: US for United States). [optional]</li>
  #     <li><strong>phone_country_code</strong> First field of the phone number. This is the number related to the country the phone number is from. (Eg. For United States it would be "1"). [optional]</li>
  #     <li><strong>phone_area_code</strong> Second field of the phone number. This is the number related to the area the phone number is from. [optional]</li>
  #     <li><strong>phone_local_number</strong> Third and last field of the phone_number. This is the local number where the member will be reached. [optional]</li>
  #     <li><strong>email</strong> Members personal email. This mail will be one of our contact method and every mail will be send to this. We recommend frontend to validate mails with the following formts like: xxxxxxxxx@xxxx.xxx.xx or xxxxxx+xxx@xxxx.xxx.xx. [optional]</li>
  #     <li><strong>gender</strong> Gender of the member. The values we are recieving are "M" for male or "F" for female. [optional]</li>
  #     <li><strong>type_of_phone_number</strong> Type of the phone number the member has input (home, mobile, others). [optional] </li>
  #     <li><strong>birth_date</strong> Birth date of the member. This date is stored with format "yyyy-mm-dd" [optional]</li>
  #     <li><strong>member_group_type_id</strong> Id of the member's group type where he belongs to. Each club can has many classifications for its member's, like 'VIP' or 'Celebrity'. [optional]</li>
  #     <li><strong>external_id</strong> Member's id related to an external platform that we don't administrate. [optional]</li>
  #     <li><strong>api_id</strong> Id related to our frontend. This is only being use when we are hosting the frontend. (e.g. Autologin URL - Update member data). [optional]</li>
  #     <li><strong>credit_card</strong> Hash with credit cards information. [optional]</li>
  #     <ul>
  #       <li><strong>number</strong> Number of member's credit card, from where we will charge the membership or any other service. This value won't be save, but instead we will save a token obtained from the payment gateway. (We accept numbers and characters like "-", whitespaces and "/") </li>
  #       <li><strong>expire_month</strong> The month (in numbers) in which the credit card will expire. Eg. For june it would be 6. </li>
  #       <li><strong>expire_year</strong> The year (in numbers) in which the credit card will expire. Have in mind it is the complete year with four digits (Eg. 2014) </li>
  #     </ul>
  #   </ul>
  # @optional [Hash] setter Variable used to pass some boolean values as "wrong_phone_number".
  #   <ul>
  #     <li><strong>wrong_phone_number</strong> Boolean value that (if it is true) it will tell us to unset member's phone_number as wrong. (It will set wrong_phone_number as nil) [optional]</li>
  #     <li><strong>batch_update</strong> Boolean variable which tell us if this update was made by a member or by a system. Send 1 if you want batch_update otherwise dont send this attribute (different operations will be stored) [optional]</li>
  #     <li><strong>skip_api_sync</strong> Boolean variable which tell us if we have to sync or not user to remote api. Send 1 if you want to skip sync otherwise dont send this attribute. [optional] (e.g drupal)</li>
  #   </ul>
  #
  # @example_request 
  #   curl -v -k -X PUT --data-ascii "{\"member\":{\"first_name\":\"Megan\",\"last_name\":\"Brenann\", \"address\":\"SomeSt\",\"city\":\"Dresden\",\"state\":\"AL\",\"gender\":\"m\",\"zip\":\"12345\",\"phone_country_code\":\"1\",\"phone_area_code\":\"123\",\"phone_local_number\":\"1123\",\"birth_date\":\"1989-09-03\",\"email\":\"alice@brennan.com\",\"country\":\"US\",\"credit_card\":{\"number\":\"371449635398431\",\"expire_month\":\"2\",\"expire_year\":\"2014\"}},\"api_key\":\"o6ESwPCNtsMkJnDLzvpC\"}" -H "Content-Type: application/json" https://dev.stoneacrehq.com:3000/api/v1/members/1
  # @example_request_description Requesting member update with valid params and in json format.
  #
  # @example_response 
  #   {"message":"Member updated successfully","code":"000","member_id":1}
  # @example_response_description Example response to a valid request
  #
  # @response_field [String] message Shows the method results and also informs the errors.
  # @response_field [String] code Code related to the method result.
  # @response_field [Integer] member_id Member's id. Integer autoincrement value that is used by platform. It will be returned only when the request was a success.
  # @response_field [Hash] errors A hash with members errors.
  #   <ul>
  #     <li> <strong>key</strong> member's field name with error. (Eg: first_name, last_name, etc.). </li>
  #     <li> <strong>value</strong> Array of strings with errors. (Eg: ["can't be blank","is invalid"]). </li>
  #   </ul>
  def update
    response = {}
    batch_update = params[:setter] && params[:setter][:batch_update] && params[:setter][:batch_update].to_s.to_bool
    member = Member.find(params[:id])

    my_authorize! :api_update, Member, member.club_id
    member.skip_api_sync! if params[:setter] && params[:setter][:skip_api_sync] && params[:setter][:skip_api_sync].to_s.to_bool
    if params[:member][:api_id].present? and batch_update
      member.api_id = ( params[:member][:api_id].blank? ? nil : params[:member][:api_id] ) 
    end 
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
  rescue NoMethodError => e
    render json: { :message => "There are some params missing. Please check them.", :code => Settings.error_codes.wrong_data }
  rescue ActiveRecord::RecordNotUnique
    render json: { :message => "Member information is invalid.", :code => Settings.error_codes.wrong_data, :errors => { :api_id => ["has already been taken"] }}
  end

  ##
  # Returns information related to member's information, credit card, current membership and enrollment information.
  #
  # @resource /api/v1/members/:id/profile
  # @action POST
  #
  # @required [String] api_key Agent's authentication token. This token allows us to check if the agent is allowed to request this action.
  # @required [Integer] id Member's ID. Integer autoincrement value that is used by platform. Have in mind this is part of the url.
  # @response_field [Hash] credit_card Information related to member's credit card.
  #  <ul>
  #     <li><strong>last_4_digits</strong> Member's active credit card last four digits. </li>
  #     <li><strong>expire_month</strong> The month (in numbers) in which the credit card will expire. Eg. For june it would be 6. </li>
  #     <li><strong>expire_year</strong> The year (in numbers) in which the credit card will expire. Have in mind it is the complete year with four digits (Eg. 2014) </li>
  #  </ul>
  # @response_field [Hash] current_membership Information related to the member's membership at the moment.
  #  <ul>
  #     <li><strong>status</strong> String with member's current status. </li>
  #     <li><strong>join_date</strong> String with date when the member join. This date is updated each time the member is recovered, or it is saved the sale. It is in datetime with the offset format. (Eg: "2013-04-23T15:17:09-04:00" ) </li>
  #     <li><strong>cancel_date</strong> String with date schedule when the member will be canceled. If there is no date schedule this value will be null. It is in datetime with the offset format. If member does not have cancel date set, this value will be blank. (Eg: "2013-04-23T15:17:09-04:00" )  </li>
  #  </ul>
  # @response_field [Hash] member Hash with member information.
  #  <ul>
  #     <li><strong>first_name</strong> The first name of the member that is enrolling. We are not accepting any invalid character (like: #$"!#%&%"). </li>
  #     <li><strong>last_name</strong> The last name of the member that is enrolling. We are not accepting any invalid character (like: #$"!#%&%"). </li>
  #     <li><strong>address</strong> The address of the member that is being enrolled. </li>
  #     <li><strong>city</strong> City from where the member is from. </li>
  #     <li><strong>state</strong> The state standard code where the member is from. </li>
  #     <li><strong>zip</strong> Member's address's zip code. We are accpeting only formats like: xxxxx or xxxxx-xxxx for US. Only numbers. In case the member is from Canada, we accept canadian zips with the valid format (LNL NLN or LNLNLN where 'L' stands for letters and 'N' for numbers.) </li>
  #     <li><strong>phone_country_code</strong> First field of the phone number. This is the number related to the country the phone number is from. (Eg. For United States it would be "011"). </li>
  #     <li><strong>phone_area_code</strong> Second field of the phone number. This is the number related to the area the phone number is from. </li>
  #     <li><strong>phone_local_number</strong> Third and last field of the phone_number. This is the local number where the member will be reached. </li>
  #     <li><strong>phone_local_number</strong> Members personal email. This mail will be one of our contact method and every mail will be send to this. We are accepting mails with formtas like: xxxxxxxxx@xxxx.xxx.xx or xxxxxx+xxx@xxxx.xxx.xx </li>
  #     <li><strong>type_of_phone_number</strong> Type of the phone number the member has input (home, mobile, others). </li>
  #     <li><strong>birth_date</strong> Birth date of the member. This date is stored with format "yyyy-mm-dd" </li>
  #     <li><strong>gender</strong> Gender of the member. The values we are recieving are "M" for male or "F" for female. </li>
  #     <li><strong>bill_date</strong> Date when the billing will be done. It is in datetime with the offset format. If member does not have bill date set, this value will be blank. (Eg: "2013-04-23T15:17:09-04:00" ) </li>
  #     <li><strong>wrong_address</strong> Reason the member was set as undeliverable. </li>
  #     <li><strong>wrong_phone_number</strong> Reason the member was set as unreachable. </li>
  #     <li><strong>member_since_date</strong> Date when the member was created. It is in datetime with the offset format. </li>
  #     <li><strong>reactivation_times</strong> Integer value that tells us how many times this member was recovered. </li>
  #     <li><strong>blacklisted</strong> Boolean value that says if the member is blacklisted or not (true = blacklisted, false = not blacklisted) </li>
  #     <li><strong>external_id</strong> Member's id related to an external platform that we don't administrate. </li>
  #     <li><strong>member_group_type</strong> Group type the member belongs to. </li>
  #     <li><strong>preferences</strong> Information about the preferences selected when enrolling. This will be use to know about the member likes. </li>
  # @response_field [String] message Shows the method errors. This message will be only shown when there was an error. 
  # @response_field [String] code Code related to the method result.
  # 
  # @example_request
  #   curl -v -k -X POST -d "api_key=DyqgeuHrxmb9QA8gsU22" https://dev.stoneacrehq.com:3000/api/v1/members/1/profile
  # @example_request_description Example of valid request.
  #
  # @example_response
  #   {"code":"000","member":{"first_name":"Megan","last_name":"Brenann","email":"alice@brennan.com","address":"SomeSt","city":"Dresden","state":"AL","zip":"12345","birth_date":"1989-09-03","phone_country_code":1,"phone_area_code":123,"phone_local_number":1123,"type_of_phone_number":"other","gender":"","bill_date":null,"wrong_address":null,"wrong_phone_number":null,"member_since_date":"2013-01-15T13:03:07-05:00","reactivation_times":0,"external_id":null,"blacklisted":false,"member_group_type":"VIP","preferences":{"example_color":"blue","example_team":"example"}},"credit_card":{"last_4_digits":"8431","expire_month":2,"expire_year":2014},"current_membership":{"status":"lapsed","join_date":"2013-01-15T13:03:19-05:00","cancel_date":"2013-04-10T20:00:00-04:00"}}
  # @example_response_description Example response to a valid request
  #
  def show
    member = Member.find(params[:id])
    my_authorize! :api_profile, Member, member.club_id
    club = member.club
    membership = member.current_membership
    credit_card = member.active_credit_card
    response = {
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
        gender: member.gender,
        bill_date: member.next_retry_bill_date.nil? ? '' : member.next_retry_bill_date.to_datetime.change(:offset => "#{(Time.zone.now.in_time_zone(club.time_zone).utc_offset)/(60*60)}").to_s,
        wrong_address: member.wrong_address,
        wrong_phone_number: member.wrong_phone_number,
        member_since_date: member.member_since_date.to_datetime.change(:offset => "#{(Time.zone.now.in_time_zone(club.time_zone).utc_offset)/(60*60)}").to_s,
        reactivation_times: member.reactivation_times,
        external_id: member.external_id,
        blacklisted: member.blacklisted,
        member_group_type: ( member.member_group_type.nil? ? nil : member.member_group_type.name ),
        preferences: member.preferences
      },
      credit_card: {
        last_4_digits: credit_card.last_digits,
        expire_month: (credit_card && credit_card.expire_month),
        expire_year: (credit_card && credit_card.expire_year)
      },
      current_membership:{
        status: membership.status,
        join_date: membership.join_date.to_datetime.change(:offset => "#{(Time.zone.now.in_time_zone(club.time_zone).utc_offset)/(60*60)}").to_s,
        cancel_date: membership.cancel_date.nil? ? '' : membership.cancel_date.to_datetime.change(:offset => "#{(Time.zone.now.in_time_zone(club.time_zone).utc_offset)/(60*60)}").to_s
      }
    }
    response.merge!( external_id: member.external_id ) if member.club.requires_external_id
    render json: response
  rescue ActiveRecord::RecordNotFound
    render json: { code: Settings.error_codes.not_found, message: 'Member not found' }
  end    

  ##
  # Updates member's club cash's data. Have in mind that in order to use this feature, member's club must allow club cash transaction within it.  
  # 
  # @resource /api/v1/members/:id/club_cash
  # @action PUT
  # 
  # @required [String] api_key Agent's authentication token. This token allows us to check if the agent is allowed to request this action.
  # @required [Integer] id Member's ID. Integer autoincrement value that is used by platform. Have in mind this is part of the url.
  # @required [Float] amount club cash amount to be set on this member profile. We only accept numbers with up to two digits after the comma.
  # @optional [String] expire_date club cash expiration date. This date is stored with datetime format. (Format "yyyy-mm-dd")
  # @response_field [String] message Shows the method results and also informs the errors.
  # @response_field [String] code Code related to the method result.
  #
  # @example_request
  #   curl -v -k -X PUT -d "api_key=G6qq3KzWQVi9zgfFVXud&amount=102&expiration_date=2013-02-02" https://dev.stoneacrehq.com:3000/api/v1/members/1/club_cash
  # @example_request_description Example of valid request.
  #
  # @example_response
  #   {"message":"Member updated successfully","code":"000"}
  # @example_response_description Example response to a valid request.
  #
  def club_cash
    member = Member.find(params[:id])
    my_authorize! :api_update_club_cash, Member, member.club_id
    response = { :message => "This club is not allowed to fix the amount of the club cash on members.", :code => Settings.error_codes.club_cash_cant_be_fixed, :member_id => member.id }
    if params[:amount].blank?
      response = { :message => "Check amount value, please. Amount cannot be blank or null.", :code => Settings.error_codes.wrong_data }
    elsif not member.club.allow_club_cash_transaction?
      response = { :message =>I18n.t("error_messages.club_cash_not_supported"), :code => Settings.error_codes.club_does_not_support_club_cash }
    elsif not member.club.club_cash_transactions_enabled
      member.skip_api_sync!
      member.club_cash_amount = params[:amount]
      member.club_cash_expire_date = params[:expire_date]
      member.save(:validate => false)
      message = "Member updated successfully"
      Auditory.audit(current_agent, member, message, member, Settings.operation_types.profile_updated)
      response = { :message => message, :code => Settings.error_codes.success }
    end
    render json: response
  rescue ActiveRecord::RecordNotFound
    render json: { :message => "Member not found", :code => Settings.error_codes.not_found }
  end

  ##
  # Updates member's next retry bill date.
  #
  # @resource /api/v1/members/:id/next_bill_date
  # @action PUT
  #
  # @required [String] api_key Agent's authentication token. This token allows us to check if the agent is allowed to request this action.
  # @required [Integer] id Member's ID. Integer autoincrement value that is used by platform. Have in mind this is part of the url.
  # @required [String] next_bill_date Date when we should bill this member, an it is stored with datetime format. It also supports UTC format. Have in mind that in this case it is not necessary to send the offset, since we set it according to the club's configuration.(Format "yyyy-mm-dd", “dd/mm/yyyy” or "yyyy-mm-ddThh:mm:ss") (Eg: "2013-04-23" or "2013-04-23T15:17:09") 
  # @response_field [String] message Shows the method result.
  # @response_field [Integer] code Code related to the method result.
  # @response_field [Hash] errors A hash with member and next_bill_date errors. 
  # 
  # @example_request
  #   curl -v -k -X PUT -d "api_key=G6qq3KzWQVi9zgfFVXud&next_bill_date=2013-05-21" https://dev.stoneacrehq.com:3000/api/v1/members/1/next_bill_date
  # @example_request_description Example of valid request. 
  #
  # @example_response
  #   {"message":"Next bill date changed to 2013-05-21","code":"000"}
  # @example_response_description Example response to a valid request.
  #
  def next_bill_date
    member = Member.find params[:id]
    my_authorize! :api_change_next_bill_date, Member, member.club_id
    render json: member.change_next_bill_date(params[:next_bill_date], @current_agent)
  rescue ActiveRecord::RecordNotFound
    render json: { :message => "Member not found", :code => Settings.error_codes.not_found }
 end 

  ##
  # Gets an array with all member's id that were updated between the dates given. 
  #
  # @resource /api/v1/members/find_all_by_updated/:club_id/:start_date/:end_date
  # @action POST
  #
  # @required [String] api_key Agent's authentication token. This token allows us to check if the agent is allowed to request this action.
  # @required [Integer] club_id Club's ID needed to find the club where we are going to check for members. 
  # @required [String] start_date Date where we will start the query from. This date must be in datetime format. Have in mind that this value is part of the url.
  # @required [String] end_date Date where we will end the query. This date must be in datetime format. Have in mind that this value is part of the url. 
  # @response_field [String] message Shows the method result. This message will be shown when there is an error.
  # @response_field [Array] list Array with member's id updated between the dates given. This list will be returned only when this method is success.
  # @response_field [String] code Code related to the method result.
  # 
  # @example_request
  #   curl -v -k -X POST -d "api_key=G6qq3KzWQVi9zgfFVXud" https://dev.stoneacrehq.com:3000/api/v1/members/find_all_by_updated/2/2013-03-20/2013-03-22
  # @example_request_description Example of valid request. 
  #
  # @example_response
  #   { "list":[20,21,22,24,25],"code":"000" }
  # @example_response_description Example response to a valid request.
  #
  def find_all_by_updated
    my_authorize! :api_find_all_by_updated, Member, params[:club_id]
    if params[:start_date].blank? or params[:end_date].blank?
      answer = { :message => "Make sure to send both start and end dates, please. There seems to be at least one as null or blank", :code => Settings.error_codes.wrong_data }
    elsif params[:start_date].to_datetime > params[:end_date].to_datetime
      answer = { :message => "Check both start and end date, please. Start date is greater than end date.", :code => Settings.error_codes.wrong_data }
    else
      members_list = ( Member.where :updated_at =>(params[:start_date].to_datetime)..(params[:end_date].to_datetime), :club_id => params[:club_id] ).collect &:id
      answer = { :list => members_list, :code => Settings.error_codes.success }
    end
    render json: answer
  rescue ArgumentError => e
    render json: { :message => "Check both start and end date format, please. It seams one of them is in an invalid format", :code => Settings.error_codes.wrong_data }
  end

  ##
  # Gets an array with all member's id that were created between the dates given.
  #
  # @resource /api/v1/members/find_all_by_created/:club_id/:start_date/:end_date
  # @action POST
  #
  # @required [String] api_key Agent's authentication token. This token allows us to check if the agent is allowed to request this action.
  # @required [Integer] club_id Club's ID needed to find the club where we are going to check for members. 
  # @required [String] start_date Date where we will start the query from. This date must be in datetime format. Have in mind that this value is part of the url. 
  # @required [String] end_date Date where we will end the query. This date must be in datetime format. Have in mind that this value is part of the url.
  # @response_field [String] message Shows the method result. This message will be shown when there is an error.
  # @response_field [Array] list Array with member's id created between the dates given. This list will be returned only when this method is success.
  # @response_field [String] code Code related to the method result.
  # 
  # @example_request
  #   curl -v -k -X POST -d "api_key=G6qq3KzWQVi9zgfFVXud" https://dev.stoneacrehq.com:3000/api/v1/members/find_all_by_created/2/2013-03-20/2013-03-22
  # @example_request_description Example of valid request. 
  #
  # @example_response
  #   {"list":[11349950041,11349950042,11349950043,11349950044,11349950045,11349950046,11349950047,11349950048],"code":"000"}
  # @example_response_description Example response to a valid request.
  #
  def find_all_by_created
    my_authorize! :api_find_all_by_updated, Member, params[:club_id]
    if params[:start_date].blank? or params[:end_date].blank?
      answer = { :message => "Make sure to send both start and end dates, please. There seems to be at least one as null or blank", :code => Settings.error_codes.wrong_data }
    elsif params[:start_date].to_datetime > params[:end_date].to_datetime
      answer = { :message => "Check both start and end date, please. Start date is greater than end date.", :code => Settings.error_codes.wrong_data }
    else
      members_list = ( Member.where :created_at =>(params[:start_date].to_datetime)..(params[:end_date].to_datetime), :club_id => params[:club_id] ).collect &:id
      answer = { :list => members_list, :code => Settings.error_codes.success }
    end
    render json: answer
  rescue ArgumentError => e
    render json: { :message => "Check both start and end date format, please. It seams one of them is in an invalid format", :code => Settings.error_codes.wrong_data } 
  end

  ##
  # Sets member's cancelation date. In case the member is already canceled, or it has the cancelation date set, we won't excecute the request. 
  #
  # @resource /api/v1/members/:id/cancel
  # @action PUT
  #
  # @required [String] api_key Agent's authentication token. This token allows us to check if the agent is allowed to request this action.
  # @required [Integer] id Member's ID. Integer autoincrement value that is used by platform. Have in mind this is part of the url.
  # @required [String] cancel_date Date when we are going to cancel the member. This date is stored in date format. (Format: "yyyy-mm-dd")
  # @required [String] reason Reason why the member is being canceled.
  # @response_field [String] message Shows the method result.
  # @response_field [Integer] code Code related to the method result.
  # 
  # @example_request
  #   curl -v -k -X PUT -d "api_key=G6qq3KzWQVi9zgfFVXud&cancel_date=2013-05-21&reason=Did not know I have enrolled" https://dev.stoneacrehq.com:3000/api/v1/members/3/cancel
  # @example_request_description Example of valid request. 
  #
  # @example_response
  #   {"message":"Member cancellation scheduled to 2013-05-21 - Reason: Did not know I have enrolled","code":"000"}
  # @example_response_description Example response to a valid request.
  #
  def cancel
    member = Member.find params[:id]
    my_authorize! :api_cancel, Member, member.club_id
    render json: member.cancel!(params[:cancel_date], params[:reason], @current_agent)
  rescue ActiveRecord::RecordNotFound
    render json: { :message => "Member not found", :code => Settings.error_codes.not_found }
  rescue ArgumentError => e
    render json: { :message => "Check cancel date, please. It seams that it is in the wrong format.", :code => Settings.error_codes.wrong_data }
  end
end