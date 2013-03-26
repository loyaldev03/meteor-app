class Api::OperationController < ApplicationController


  ##
  # Creates a new operation related to a member
  #
  # @resource /api/v1/members/:member_id/operation
  # @action POST
  #
  # @required [String] api_key Agent's authentication token. This token allows us to check if the agent is allowed to request this action.
  # @required [String] member_id Member's ID. This ID is unique for each member. (32 characters string). This value is used by platform. Have in mind that this value is part of the url.
  # @required [Integer] description Description of the operation. It is a text field.
  # @required [Integer] operation_type message Integer value related to the operation type. Operations supported at the moment:
  #   </br>&nbsp&nbsp&nbsp&nbsp<strong>[900]</strong> vip_event_registration
  #   </br>&nbsp&nbsp&nbsp&nbsp<strong>[901]</strong> vip_event_cancelation  # @response_field [String] 
  # @required [String] operation_date If this value is nil we save that operation with Time.zone.now
  # @response_field [Integer] code Code related to the method result.
  # @response_field [String] message Shows the method results and also informs the errors.
  # 
	def create
    begin
    	member = Member.find(params[:member_id])      
    	Auditory.audit(@current_agent, member, params[:description], member, params[:operation_type], params[:operation_date])
			render json: { :message => 'Operation created succesfully.', :code => Settings.error_codes.success }
		rescue Exception => e
			render json: { :message => "Operation was not created. Errors: #{e}", :code => Settings.error_codes.operation_not_saved}
		end			
	end

  # TODO: Add a list of operation types: 
  # {include:file:config/application.yml}

end