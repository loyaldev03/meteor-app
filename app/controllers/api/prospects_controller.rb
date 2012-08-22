class Api::ProspectsController < ApplicationController
  skip_before_filter :verify_authenticity_token
  before_filter :check_authentification

  respond_to :json

  # Method  : POST
  # Creates prospect with data that we recieve. We don't validate this data.
  #
  # [prospect] Information related to the prospect.
  #                             *terms_of_membership_id: 
  #                             *first_name: Prospect's first name.
  #                             *last_name: Prospect's last name.
  #                             *gender:
  #                             *address: Address registered by the prospect.
  #                             *city: City registered by the prospect. 
  #                             *state: State registered by the prospect.
  #                             *zip: Zip registered by the prospect.
  #                             *country:
  #                             *referral_parameters:
  #                             *email: Email registered by the prospect.
  #                             *phone_country_code: First field of the phone number. This is the number related to the country the phone number is from. (Eg. For United States it would be "011"). 
  #                             *phone_area_code: Second field of the phone number. This is the number related to the area the phone number is from. 
  #                             *phone_local_number: Third and las field of the phone_number. This is the local number of the phone number.
  #                             *type_of_phone_number
  #                             *birth_date: Birth date of the prospect
  #                             *product_sku: Name of the selected product.
  #                             *product_description:
  #                             *marketing_code: multi-team
  #                             *campaign_medium
  #                             *campaign_description
  #                             *campaign_medium_version
  #                             *fulfillment_code
  #                             *mega_channel:
  #                             *ip_address: Ip address from where the enrollment is being submitted.
  #                             *user_agent: Information related to the browser and computer from where the enrollment is being submitted.
  #                             *referral_host: Link where is being redirect when after subimiting the enroll. (It shows the params in it),
  #                             *referral_path
  #                             *user_id
  #                             *landing_url: Url from where te submit comes from.
  #                             *preferences: Information about the preferences selected when enrolling. This will be use to know about the member likes.
  #                             *cookie_set
  #                             *cookie_value: Cookie from where the enrollment is being submitted.
  #                             *joint
  # [message] Shows the method results and also informs the errors.
  # [code] Code related to the method result.
  # [prospect_id] ID of the prospect. This ID is unique for each prospect. (32 characters string)
  #
  # @param [Hash] prospect
  # @return [string] *message*
  # @return [Integer] *code*
  # @return [String] *prospect_id*
  def create
  	response = { :message => "prospect_data_invalid", :code => '405' }
  	prospect = Prospect.new(params[:prospect])
  	if prospect.save
  	  response[:message] = "Prospect was successfuly saved."
      response[:code] = '000'
      response[:prospect_id] = prospect.id
    end   
    render json: response
  end

  private
    def check_authentification
      authorize! :manage_prospects_api, Member
    end
end