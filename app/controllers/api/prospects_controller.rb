class Api::ProspectsController < ApplicationController
  skip_before_filter :verify_authenticity_token
  respond_to :json

  ##
  # Creates prospect with data that we recieve. We don't validate this data.
  #
  # @resource /api/v1/prospects
  # @action POST
  #
  # @required [String] api_key Agent's authentication token. This token allows us to check if the agent is allowed to request this action.
  # @required [Hash] prospect Information related to the prospect.
  #  <ul>
  #     <li><strong>first_name</strong> The first name of the member that is enrolling. [optional] </li>
  #     <li><strong>last_name</strong> The last name of the member that is enrolling. [optional] </li>
  #     <li><strong>address</strong> The address of the member that is being enrolled. [optional]  </li>
  #     <li><strong>city</strong> City from where the member is from.[optional]</li>
  #     <li><strong>state</strong> The state standard code where the member is from. [optional]</li>
  #     <li><strong>zip</strong> Member's address's zip code. We are accepting only formats like: xxxxx or xxxxx-xxxx. Only numbers.[optional]</li>
  #     <li><strong>country</strong> The country standard code where the member is from. This code has a length of 2 digits. (Eg: US for United States).[optional]</li>
  #     <li><strong>phone_country_code</strong> First field of the phone number. This is the number related to the country the phone number is from. (Eg. For United States it would be "1"). [optional]</li>
  #     <li><strong>phone_area_code</strong> Second field of the phone number. This is the number related to the area the phone number is from. [optional]</li>
  #     <li><strong>phone_local_number</strong> Third and last field of the phone_number. This is the local number where the member will be reached.[optional]</li>
  #     <li><strong>email</strong> Members personal email. This mail will be one of our contact method and every mail will be send to this. We recommend frontend to validate mails with the following formts like: xxxxxxxxx@xxxx.xxx.xx or xxxxxx+xxx@xxxx.xxx.xx </li>
  #     <li><strong>gender</strong> Gender of the member. The values we are recieving are "M" for male or "F" for female.[optional]</li>
  #     <li><strong>type_of_phone_number</strong> Type of the phone number the member has input (home, mobile, others).[optional]</li>
  #     <li><strong>terms_of_membership_id</strong> This is the id of the term of membership the member is enrolling with. With this param we will set some features such as provisional days or amount of club cash the member will start with. It is present at prospect level. </li>
  #     <li><strong>birth_date</strong> Birth date of the member. This date is stored with format "yyyy-mm-dd"[optional]</li>
  #     <li><strong>product_sku</strong> Freeform text that is representative of the SKU. This will be passed with format string, each product separated with ',' (comma). (Example: "kit-card,circlet") [optional]</li>
  #     <li><strong>utm_campaign</strong>[optional]</li>
  #     <li><strong>audience</strong> multi-team[optional]</li>
  #     <li><strong>campaign_id</strong> Id of the fulfillment we are sending to our member. (car-flag).[optional]</li>
  #     <li><strong>ip_address</strong> Ip address from where the enrollment is being submitted.[optional]</li>
  #     <li><strong>user_agent</strong> Information related to the browser and computer from where the enrollment is being submitted.[optional]</li>
  #     <li><strong>referral_host</strong> Link where is being redirect when after subimiting the enroll. (It shows the params in it).[optional]</li>
  #     <li><strong>referral_parameters</strong> [optional]</li>
  #     <li><strong>referral_path</strong> [optional]</li>
  #     <li><strong>visitor_id</strong> User ID alias UID is an md5 hash of the user's IP address and user-agent information.[optional]</li>
  #     <li><strong>landing_url</strong> Url from where the submit comes from.[optional]</li>
  #     <li><strong>preferences</strong> Information about the preferences selected when enrolling. This will be use to know about the member likes. This information is selected by the member. This information is stored with format as hash encoded with json. [optional]</li>
  #     <li><strong>cookie_value</strong> Cookie from where the enrollment is being submitted.[optional]</li>
  #     <li><strong>cookie_set</strong> If the cookie_value is being recieved or not. It also informs if the client has setted a cookie on his side.[optional]</li>
  #     <li><strong>utm_source</strong> [optional]</li>
  #     <li><strong>utm_medium</strong> [optional]</li>
  #     <li><strong>campaign_description</strong> The name of the campaign.[optional]</li>
  #     <li><strong>utm_content</strong> [optional]</li>
  #     <li><strong>joint</strong> It shows if it is set as type joint. It is use to see if at the end of the contract we have with the partner, we share the member's informatión with him. joint=1 means we will share this informatión. If it is null, we will automaticaly set it as 0. This is an exclusive value, it can be seted using 1 or 0, or true or false. It is present at member level. [optional]</li>
  #  </ul>
  # @response_field [String] message Shows the method results and also informs the errors.
  # @response_field [String] code Code related to the method result.
  # @response_field [String] prospect_id Prospect's id. This ID is unique for each prospect. (36 characters string)
  #
  # @example_request
  #   curl -v -k -X POST --data-ascii '{"prospect":{"first_name":"Megan", "last_name":"Brenann", "address":"SomeSt", "city":"Dresden", "state":"AL", "gender":"m", "zip":"12345", "phone_country_code":"1", "phone_area_code":"123", "phone_local_number":"1123", "birth_date":"1989-09-03", "email":"alice@brennan.com", "country":"US", "terms_of_membership_id":"1"}, "api_key":"3v5L15ovoJyee8mKh5DQ"}' -H "Content-Type: application/json" https://dev.affinitystop.com:3000/api/v1/prospects
  # @example_request_description Example of request.
  #
  # @example_response
  #   {"message":"Prospect was successfuly saved.", "code":"000", "prospect_id":"55e8f945-9d24-4d10-95cd-b0dcfcdb7f5c"}
  # @example_response_description Example response to valid request.
  #
  def create
    if params[:prospect].nil?
      render json: { :message => "There are some params missing. Please check them.", :code => Settings.error_codes.wrong_data }
    else
      tom = TermsOfMembership.find(params[:prospect][:terms_of_membership_id])
      my_authorize! :manage_prospects_api, Prospect, tom.club_id
      response = { :message => "Prospect data invalid", :code => Settings.error_codes.prospect_data_invalid }
      standarize_params(params[:prospect])
      prospect = Prospect.new params.require(:prospect).permit(:first_name, :last_name, :address, :city, :state, :zip, :email,:phone_country_code, :phone_area_code ,:phone_local_number, :birth_date, :gender, :ip_address, :referral_host, :referral_parameters, :cookie_value, :audience, :product_sku, :visitor_id, :landing_url, :utm_campaign, :user_agent, :joint, :utm_medium, :campaign_description, :utm_content , :terms_of_membership_id, :country, :type_of_phone_number, :referral_path, :cookie_set, :product_description, :utm_source, :campaign_code)
      prospect.club_id = tom.club_id
      prospect.preferences = params[:prospect][:preferences]
      if prospect.save
        Auditory.audit(current_agent, prospect, "User visits checkout page.", nil, Settings.operation_types.checkout_page_visit)
        response[:message] = "Prospect was successfuly saved."
        response[:code] = Settings.error_codes.success
        response[:prospect_id] = prospect.id
      end
      render json: response
    end
  rescue ActiveRecord::RecordNotFound
    render json: { :message => "Subscription plan not found", :code => Settings.error_codes.not_found }
  end

  ##
  # Fetches information related to the prospect
  #
  # @resource /api/v1/prospects/:token
  # @action POST
  #
  # @required [String] api_key Agent's authentication token. This token allows us to check if the agent is allowed to request this action.
  # @required [String] token Prospect's identifier used to fetch prospect's inforamtion.
  # @response_field [Hash] prospect Hash with prospect information.
  #  <ul>
  #     <li><strong>first_name</strong> The prospect's first name.</li>
  #     <li><strong>last_name</strong> The prospect's last name.</li>
  #     <li><strong>email</strong> The prospect's email address.</li>
  #     <li><strong>address</strong> The prospect's address.</li>
  #     <li><strong>city</strong> City from where the prospect is from.</li>
  #     <li><strong>state</strong> The state standard code where the prospect is from.</li>
  #     <li><strong>zip</strong> Prospect's address's zip code.</li>
  #     <li><strong>phone</strong> The country and area area code concatenated with the local phone number.</li>
  #     <li><strong>preferences</strong> Hash with the prospect's preferences.</li>
  #     <li><strong>error_messages</strong> Hash with the prospect's errors .</li>
  # @response_field [String] code Code related to the method result.
  #
  # @example_request
  #   curl -v -k -X POST --data-ascii '{"api_key":"3v5L15ovoJyee8mKh5DQ"}' -H "Content-Type: application/json" https://dev.affinitystop.com:3000/v1/prospects/MSwyMDE2LTExLTAxIDEyOjI2OjU4IFVUQw==\n
  # @example_request_description Example of request.
  #
  # @example_response
  #   {"prospect":{"first_name":"alice","last_name":"brennan","address":"someSt","city":"Dresden","state":"AL","zip":"12345","email":"alice@brennan.com","preferences":{"driver_1"=>"Busch, Kurt"},"product_sku":"PRODUCTSKU","country":"US","error_messages":{:phone=>["Wrong phone number"]},"phone":""}
  # @example_response_description Example response to valid request.
  #
  def show
    if params[:token]
      prospect = Prospect.where_token(params[:token])
      if prospect
        my_authorize! :show_prospects_api, Prospect, prospect.club_id
        prospect_attributes = prospect.as_json(only: [ :first_name, :last_name, :email, :city, :zip, :state, :country, :address, :preferences, :product_sku, :error_messages ]).merge!(phone: phone_for_landing(prospect))
        render json: { prospect: prospect_attributes, code: Settings.error_codes.success }
      else
        render json: { :message => "Prospect not found", :code => Settings.error_codes.not_found }
      end
    else
      render json: { :message => "There are some params missing. Please check them.", :code => Settings.error_codes.wrong_data }
    end
  end

  private
    def standarize_params(params)
      params[:email]          = params[:email].downcase if params[:email]
      params[:product_sku]    = params[:product_sku].upcase if params[:product_sku]
      params[:utm_campaign]   = params[:utm_campaign].downcase if params[:utm_campaign]
      params[:audience]       = params[:audience].downcase if params[:audience]
      params[:campaign_code]  = params[:campaign_id].downcase if params[:campaign_id]
      params[:landing_url]    = params[:landing_url].downcase if params[:landing_url]
      params[:utm_medium]     = params[:utm_medium].downcase if params[:utm_medium]
      params[:utm_content]    = params[:utm_content].downcase if params[:utm_content]
      params[:referral_path]  = params[:referral_path].truncate(255) if params[:referral_path]
      params[:user_agent]     = params[:user_agent].truncate(255) if params[:user_agent]
    end

    def phone_for_landing(prospect)
      return '' unless prospect.phone.to_i > 0
      "(#{prospect.phone_area_code.to_s}) #{prospect.phone_local_number.to_s[0..2]}-#{prospect.phone_local_number.to_s[3..6]}"
    end
end
