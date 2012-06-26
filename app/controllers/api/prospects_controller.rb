class Api::ProspectsController < ApplicationController
  skip_before_filter :verify_authenticity_token

  respond_to :json

  def enroll
  	response = { :message => "prospect_data_invalid", :code => '405' }
  	prospect = Prospect.new(params[:prospect])
  	if prospect.save!
  	  response[:message] = "Prospect was successfuly saved."
      response[:code] = '000'
    end   
    render json: response
  end


end