class Api::ProspectsController < ApplicationController
  skip_before_filter :verify_authenticity_token

  respond_to :json

  # Method  : POST
  #
  # Recieves:
  # * prospect: Information related to the prospect
  # Returns:
  # * message: Shows the method results and also informs the errors.
  # * code: Code related to the method result.
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