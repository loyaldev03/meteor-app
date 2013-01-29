class Api::ClubCashController < ApplicationController

  # Method : POST
  #
  # This method adds or remove an specific amount of club cash on a member. In case you want to add club cash, the amount value 
  # has to be a positive number, while if you want to remove club cash, the amount value has to be negative.  
  #
  # [member_id] ID of the member. This ID is unique for each member. (32 characters string). This value is used by platform. API users dont 
  # know the member id at this moment.
  # [amount] Amount of the club cash to add or It. deduct should be float and only number. We accept a maximun of two digits after the comma.
  # (Example: 2.50 , -10.99, 25)
  # [description] Description of the club cash. (Eg. why we are adding club cash to the member.)
  # [message] Shows the method results and also informs the errors.
  # [code] Code related to the method result.
  # [errors] A hash with club cash and members errors. This will be use to show errors on club cash cs web page.
  #
  # @param [String] member_id
  # @param [float] amount
  # @param [Text] description
  # @return [String] *message*
  # @return [Integer] *code*
  # @return [Hash] *errors*
  #
  
  def create
    member = Member.find(params[:member_id])
    my_authorize! :manage_club_cash_api, Member, member.club_id
    render json: member.add_club_cash(current_agent,params[:club_cash_transaction][:amount],params[:club_cash_transaction][:description])
  rescue ActiveRecord::RecordNotFound
    render json: { :message => "Member not found", :code => Settings.error_codes.not_found }
  end

end
