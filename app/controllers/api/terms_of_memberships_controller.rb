class Api::TermsOfMembershipsController < ApplicationController
  skip_before_filter :verify_authenticity_token
  respond_to :json


  ##
  # Change actual terms of membership related to a member.
  #
  # @resource /api/v1/members/:member_id/terms_of_membership_change
  # @action POST
  #
  # @required [Integer] member_id Member's ID. Integer autoincrement value that is used by platform. Have in mind this is part of the url.
  # @required [Integer] terms_of_membership_id New Terms of membership's ID to set on members.
  #
  # @response_field [String] message Shows the method results and also informs the errors.
  # @response_field [String] code Code related to the method result.
  # @response_field [Integer] member_id Member's id. Integer autoincrement value that is used by platform. This value will be returned only if the member is enrolled successfully.
  # @response_field [Hash] errors A hash with members and credit card errors.
  #   <ul>
  #     <li> <strong>key</strong> member's field name with error. (Eg: first_name, last_name, etc.). In the particular case that one or more of credit_card's field are wrong, the key will be "credit_card", and the value will be a hash that follows the same logic as this error hash. (Eg: "credit_card":{"number":["is required"],"expire_month":["is required"],"expire_year":["is required"]})  </li>
  #     <li> <strong>value</strong> Array of strings with errors. (Eg: ["can't be blank","is invalid"]). </li>
  #   </ul>
  #
  # @response_field [String] autologin_url Url provided by Drupal, used to autologin a member into it. This URL is used by campaigns in order to redirect members to their drupal account. This value wll be returned as blank in case the club is not related to drupal.
  # @response_field [String] status Member's membership status after enrolling. There are two possibles status when the member is enrolled:
  #   <ul>
  #     <li><strong>provisional</strong> The member will be within a period of provisional. This period will be set according to the terms of membership the member was enrolled with. Once the period finishes, the member will be billed, and if it is successful, it will be set as 'active'. </li>
  #     <li><strong>applied</strong> Member is in confirmation process. An agent will be in charge of accepting or rejecting the enroll. In case the enroll is accepeted, the member will be set as provisional. On the other hand, if the member is reject, it will be set as lapsed. </li>
  #   </ul> 
  #
	def change
    tom = TermsOfMembership.find(params[:terms_of_membership_id])
    member = Member.find(params[:member_id])
    my_authorize! :api_change, TermsOfMembership, tom.club_id
    render json: member.save_the_sale(params[:terms_of_membership_id], @current_agent, true)
  rescue ActiveRecord::RecordNotFound => e 
  	if e.to_s.include? "TermsOfMembership"
    	message = "Terms of membership not found"
  	elsif e.to_s.include? "Member"
    	message = "Member not found"
  	end
  	render json: { :message => message, :code => Settings.error_codes.not_found }
  rescue NoMethodError => e
    Auditory.report_issue("API::TermsOfMembership::change", e, { :params => params.inspect })
    render json: { :message => "There are some params missing. Please check them.", :code => Settings.error_codes.wrong_data }
  end
end