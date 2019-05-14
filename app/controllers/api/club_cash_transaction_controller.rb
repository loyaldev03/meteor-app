class Api::ClubCashTransactionController < ApplicationController
  skip_before_filter :verify_authenticity_token

  ##
  # This method adds or deducts an specific amount of club cash on a member. In case you want to add club cash, the amount value has to be a positive number, while if you want to remove club cash, the amount value has to be negative. Have in mind that in order to use this feature, member's club must allow club cash transaction within it.  
  #
  # @resource /api/v1/members/:member_id/club_cash_transaction
  # @action POST
  #
  # @required [String] api_key Agent's authentication token. This token allows us to check if the agent is allowed to request this action.
  # @required [Integer] Member's ID. Integer autoincrement value that is used by platform. Have in mind this is part of the url.
  # @required [Boolean] skip_api_sync Boolean to set if user should be synchronize or not against frontend.
  # @required [Hash] club_cash_transaction Hash with necessary information to create the club cash transaction. It has the following information:
  #   <ul>
  #     <li><strong>amount</strong> Amount of the club cash to add or deduct. Positive value to add, or negative value to deduct. We only accept numbers with up to two digits after the comma. (required) (Eg: 2.50 , -10.99, 25) </li>
  #     <li><strong>description</strong> Description of the club cash. (Eg. "Adding $20 club cash because of enroll.".) [optional]</li>
  #   </ul>
  # @response_field [String] message Shows the method results and also informs the errors.
  # @response_field [String] code Code related to the method result.
  # @response_field [String] errors A hash with club cash and members errors.
  #
  # @example_request
  #   curl -v -k -X POST --data-ascii '{"club_cash_transaction":{"amount":"10", "description":"testing"}, "api_key":"3v5L15ovoJyee8mKh5DQ"}' -H "Content-Type: application/json" https://dev.affinitystop.com:3000/api/v1/members/11349954802/club_cash_transaction
  # @example_request_description Example of valid request. 
  #
  # @example_response
  #   {"message":"Club cash processed at drupal correctly. Amount: 10. Concept: testing", "code":"000"}
  # @example_response_description Example response to a valid request.
  #
  def create
    user = User.find(params[:member_id])
    my_authorize! :manage_club_cash_api, ClubCashTransaction, user.club_id
    user.skip_api_sync! if params[:skip_api_sync].present?
    render json: user.add_club_cash(current_agent, params[:club_cash_transaction][:amount],params[:club_cash_transaction][:description])
  rescue ActiveRecord::RecordNotFound
    render json: { :message => "Member not found", :code => Settings.error_codes.not_found }
  rescue NoMethodError => e
    Auditory.report_issue("API::ClubCash::create", e)
    render json: { :message => "There are some params missing. Please check them. #{e}", :code => Settings.error_codes.wrong_data }
  end
end
