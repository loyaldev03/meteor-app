class Api::TokensController < ApplicationController
  skip_before_filter :verify_authenticity_token 
  skip_before_filter :authenticate_agent!

  respond_to :json

  # Method  : POST
  #
  # @param [Hash] email
  # @param [Hash] password
  # @return [string] *message*: Shows the method results and also informs the errors.
  # @return [Integer] *status*: Code related to the method result.
  # @return [String] *token*: authentication token
  # @return [String] *location*
  def create
    email = params[:email]
    password = params[:password]

    if email.nil? or password.nil?
      respond_with({:message=>"The request must contain the user email and password."}, :status=>400, 
        :location => nil)
      return
    end

    @user=Agent.find_by_email(email.downcase)

    if @user.nil?
      logger.info("User #{email} failed signin, user cannot be found.")
      respond_with({:message=>"Invalid email or passoword."}, :status=>401, :location => nil)
      return
    end

    # http://rdoc.info/github/plataformatec/devise/master/Devise/Models/TokenAuthenticatable
    @user.reset_authentication_token!

    if not @user.valid_password?(password)
      logger.info("User #{email} failed signin, password \"#{password}\" is invalid")
      respond_with({:message=>"Invalid email or passoword."}, :status=>401, :location => nil)
    else
      respond_with({:token=>@user.authentication_token}, :status=>200, :location => nil)
    end
  end


  # Method  : PUT
  #
  # @param [Integer] id
  # @return [string] *message*: Shows the method results and also informs the errors.
  # @return [Integer] *status*: Code related to the method result.
  # @return [String] *token*: authentication token
  def destroy
    @user=Agent.find_by_authentication_token(params[:id])
    if @user.nil?
      logger.info("Token not found.")
      render :status=>404, :json=>{:message=>"Invalid token."}
    else
      @user.update_attribute :authentication_token, nil
      render :status=>200, :json=>{:token=>params[:id]}
    end
  end

end

