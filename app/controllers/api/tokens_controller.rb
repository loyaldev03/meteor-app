class Api::TokensController < ApplicationController
  skip_before_filter :verify_authenticity_token 
  skip_before_filter :authenticate_agent!
  before_filter :check_authentification, :except => [:create, :destroy]
  respond_to :json
  

  ##
  # Generate token.
  #
  # @resource /api/v1/tokens
  # @action POST
  #
  # @required [String] email 
  # @required [String] password 
  # @response_field [Integer] status Code related to the method result.
  # @response_field [String] message Shows the method results and also informs the errors.
  # @response_field [String] token authentication token.
  # @response_field [String] location
  # 
  # @example_request
  #   -curl -v -k -X POST -d "email=testmail@gmail.com&password=testpassword" https://dev.affinitystop.com:3000/api/v1/tokens
  # @example_request_description Example with curl. 
  #
  # @example_response
  #   {"token":"G6qq3KzWQVi9zgfFVXud"}
  # @example_response_description Example response to valid request
  #
  def create
    email = params[:email]
    password = params[:password]

    if email.nil? or password.nil?
      respond_with({:message=>"The request must contain the user email and password."}, :status=>400, 
        :location => nil)
      return
    end

    @user = Agent.find_by(email: [email,email.downcase]) unless email.nil?
      
    if @user.nil?
      logger.info("User #{email} failed signin, user cannot be found.")
      respond_with({:message=>"Invalid email or password."}, :status=>401, :location => nil)
      return
    end

    if not @user.valid_password?(password)
      logger.info("User #{email} failed signin, password \"#{password}\" is invalid")
      respond_with({:message=>"Invalid email or password."}, :status=>401, :location => nil)
    else
      @user.generate_authentication_token
      respond_with({:token=>@user.authentication_token}, :status=>200, :location => nil)
    end
  end

  ##
  # Destroy token
  #
  # @resource /api/v1/tokens/:id
  # @action PUT
  #
  # @required [String] id Token to destroy. Have in mind this is part of the url. 
  # @response_field [Integer] status Code related to the method result.
  # @response_field [String] message Shows the method results and also informs the errors.
  # @response_field [String] token authentication token.
  #
  # @example_request
  #   curl -X PUT -d "" https://dev.affinitystop.com:3000/api/v1/tokens/dodzJDdoaYZ1XNrn7axF
  # @example_request_description Example with curl. We are passing in this example an empty body, just to make it work. (-d "")
  #
  # @example_response
  #   {"token":"G6qq3KzWQVi9zgfFVXud"}
  # @example_response_description Example response to a valid request.
  #
  def destroy
    @user=Agent.find_by(authentication_token: params[:id])
    if @user.nil?
      logger.info("Token not found.")
      render :status=>404, :json=>{:message=>"Invalid token."}
    else
      @user.update_attribute :authentication_token, nil
      render :status=>200, :json=>{:token=>params[:id]}
    end
  end

  private
    def check_authentification
      my_authorize! :manage_token_api, Agent
    end
end