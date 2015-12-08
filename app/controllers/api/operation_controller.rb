class Api::OperationController < ApplicationController
  skip_before_filter :verify_authenticity_token


  ##
  # Creates a new operation related to a member
  #
  # @resource /api/v1/members/:member_id/operation
  # @action POST
  #
  # @required [String] api_key Agent's authentication token. This token allows us to check if the agent is allowed to request this action.
  # @required [Integer] member_id Member's ID. Integer autoincrement value that is used by platform. Have in mind this is part of the url.
  # @required [Integer] operation_type message Integer value related to the operation type. Operations supported at the moment:
  #   <ul>
  #     <li><strong>900</strong> vip_event_registration </li>
  #     <li><strong>901</strong> vip_event_cancelation </li>
  #   </ul>
  # @optional [String] operation_date Date when the operation was done. If this value is nil we save that operation with actual time + offset. (Format "yyyy-mm-dd +xxxx"). If no offset is given, we will assume that it is "+0000".
  # @optional [Integer] description Description of the operation. It is a text field.
  # @response_field [String] code Code related to the method result.
  # @response_field [String] message Shows the method results and also informs the errors.
  #
  # @example_request
  #   curl -v -k -X POST -d "api_key=G6qq3KzWQVi9zgfFVXud&operation_type=900&operation_date=2013-2-12T15:20:12-04:00&description=Enrolled vip registration" https://dev.affinitystop.com:3000/api/v1/members/1/operation
  # @example_request_description Example of valid request.
  #
  # @example_response
  #   {"message":"Operation created succesfully.","code":"000"}
  # @example_response_description Example response to valid request.
  #
	def create
  	user = User.find(params[:member_id])
    
    o = Operation.new( 
      :operation_date => params[:operation_date], 
      :resource => user, 
      :description => params[:description], 
      :operation_type => params[:operation_type]
    )
    o.created_by_id = @current_agent.id
    o.user = user

    o.save!
    render json: { :message => 'Operation created succesfully.', :code => Settings.error_codes.success }
    rescue ActiveRecord::RecordInvalid => e
      Auditory.report_issue("API::Operation::create", e, { :params => params.inspect })
      render json: { :message => "Operation was not created. Errors: #{e.message}", :code => Settings.error_codes.wrong_data}
    rescue ActiveRecord::RecordNotFound => e
      Auditory.report_issue("API::Operation::create", e, { :params => params.inspect })
      render json: { :message => "Operation was not created. Errors: Member not found", :code => Settings.error_codes.not_found}
    rescue Exception => e
      Auditory.report_issue("API::Operation::create", e, { :params => params.inspect })
      render json: { :message => "Operation was not created. Errors: #{e}", :code => Settings.error_codes.operation_not_saved}
  end

  # TODO: Add a list of operation types: 
  # {include:file:config/application.yml}

end