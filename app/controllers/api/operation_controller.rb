class Api::OperationControllers < ApplicationController

	# Method : POST
  #
  # Creates a new operation related to a member
  # [url] /api/v1/members/:member_id/operation
  # [api_key] Agent's authentication token. This token allows us to check if the agent is allowed to request this action.
  # [member_id] ID of the member. This ID is unique for each member. (32 characters string). This value is used by platform.
  #      Have in mind that this value is part of the url.
  # [description] Text that describes the operation in a few words. (Eg. "VIP event number #12 registered for 2013-03-14" or "VIP event number #12 canceled" )
  # [operation_type] 
  # [operation_date] If this value is nil we save that operation with Time.zone.now
  #
  # @param [String] api_key
  # @param [String] description
  # @param [Integer] operation_type
  # @param [String] operation_date
  # @return [String] *message*
  # @return [Integer] *code*
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


end