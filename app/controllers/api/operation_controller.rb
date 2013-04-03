class Api::OperationController < ApplicationController


  ##
  # Creates a new operation related to a member
  #
  # @resource /api/v1/members/:member_id/operation
  # @action POST
  #
  # @required [String] api_key Agent's authentication token. This token allows us to check if the agent is allowed to request this action.
  # @required [Integer] member_id Member's id related to the operation we are creating. Integer autoincrement value that is used by platform. Have in mind this is part of the url.
  # @required [Integer] operation_type message Integer value related to the operation type. Operations supported at the moment:
  #   <ul>
  #     <li><strong>900</strong> vip_event_registration </li>
  #     <li><strong>901</strong> vip_event_cancelation </li>
  #   </ul>
  # @optional [String] operation_date Date when the operation was done. If this value is nil we save that operation with Time.zone.now. (Format "yyyy-mm-dd")
  # @optional [Integer] description Description of the operation. It is a text field.
  # @response_field [String] code Code related to the method result.
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