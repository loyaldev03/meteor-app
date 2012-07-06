class Api::ClubCashController < ApplicationController

  # Method : POST
  #
  # This method adds an specific amount of cash, as club cash to the member.
  #
  # [id] ID of the member inside the club. This id is an integer value. With this value and the club id we can search for the memeber.
  # [club_id] Id of the club the member belongs to. This club id is setted at the moment of enrolling according to the terms of membership that the member selected on enrollment.
  # [club_cash_transaction] Amount of club cash that is going to be added to the member. This value has to be an integer (without decimals).
  # [message] Shows the method results and also informs the errors.
  # [code] Code related to the method result.
  #
  # @param [Integer] id
  # @param [Integer] club_id.
  # @param [Hash] club_cash_transaction
  # @return [String] *message*
  # @return [Integer] *code*
  #
  def create
    response = {}
    amount = params[:club_cash_transaction][:amount] || params[:amount]
    description = params[:club_cash_transaction][:description] if params[:club_cash_transaction]
    
    member = Member.find(params[:member_id])
    if member.nil?
      response = { :message => "Member not found", :code => Settings.error_codes.not_found }  
    else
      response = member.add_club_cash(current_agent,amount,description)
    end
    render json: response
  end

end