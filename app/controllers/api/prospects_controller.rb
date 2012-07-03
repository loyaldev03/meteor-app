class Api::ProspectsController < ApplicationController
  skip_before_filter :verify_authenticity_token

  respond_to :json

  # Information related to the prospect
  # It has the following information:
  # { first_name, last_name, address, city, state, zip, email, phone_number, url_landing, club_id, terms_of_membership_id
  # birth_date, user_id, preferences, product_sku, mega_channel, marketing_code, ip_address, country, user_agen
  # user_agent, referral_host, referral_parameters, cookie_value, joint}

  attr_reader :prospect

  # Shows the method results and also informs the errors.
  attr_reader :message

  # Code related to the method result.
  attr_reader :code

  # Prospect id related to the member that was enrolled, or recoverd or updated. 
  attr_reader :prospect_id

  # Method  : POST
  #
  # Recieves:
  # * prospect
  # Returns:
  # * message
  # * code
  def enroll
  	response = { :message => "prospect_data_invalid", :code => '405' }
  	prospect = Prospect.new(params[:prospect])
  	if prospect.save!
  	  response[:message] = "Prospect was successfuly saved."
      response[:code] = '000'
      response[:prospect_id] = prospect.id
    end   
    render json: response
  end


end