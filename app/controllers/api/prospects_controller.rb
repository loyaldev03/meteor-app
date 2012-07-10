class Api::ProspectsController < ApplicationController
  skip_before_filter :verify_authenticity_token

  respond_to :json



  # Method  : POST
  # Creates prospect with data that we recieve. We don't validate this data.
  #
  # @param [Hash] prospect: Information related to the prospect.
  # @return [string] *message*: Shows the method results and also informs the errors.
  # @return [String] *code*: Code related to the method result.
  # @return [String] *prospect_id*: Prospect id that was created.
  def create
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