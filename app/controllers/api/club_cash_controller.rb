class Api::ClubCashController < ApplicationController

  # Method : POST
  #
  # This method adds an specific amount of cash, as club cash to the member.
  #
  # [member_id] ID of the member inside the club. This id is an integer value. With this value and the club id we can search for the memeber.
  # [amount] Amount of the club cash to add. It should be integer and only number.
  # [description] Description of the club cash. (Eg. why we are adding club cash to the member.)
  # [message] Shows the method results and also informs the errors.
  # [code] Code related to the method result.
  #
  # @param [String] member_id
  # @param [Integer] amount
  # @param [Text] description
  # @return [String] *message*
  # @return [Integer] *code*
  #
  def create
    response = {}

    member = Member.find(params[:member_id])
    if member.nil?
      response = { :message => "Member not found", :code => Settings.error_codes.not_found }  
    else
      response = member.add_club_cash(current_agent,params[:amount],params[:description])
    end
    render json: response  
  end

end