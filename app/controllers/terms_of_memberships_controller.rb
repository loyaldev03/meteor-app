class TermsOfMembershipsController < ApplicationController
  before_filter :validate_club_presence
  # before_filter :check_permissions

  def index
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: TermsOfMembershipDatatable.new(view_context,@current_partner,@current_club,nil,@current_agent) }
    end
  end

  def new
    @tom = TermsOfMembership.new
    @dates_span = [['Month(s)', 'months'], ['Day(s)', 'days']]
  end

  def create
    # @tom = TermsOfMembership.new(params[:tom])
    # @tom.club_id = @current_club.id
    # @tom.agent = @current_agent
    # if @tom.save
    #   redirect_to terms_of_membership_path(@current_partner.prefix,@current_club.name, @tom), 
    #     notice: 'Your Suscription Plan ' + @tom.name +  'was created Succesfully'
    # else
    #   render action: "new"
    # end
  end

  def destroy
    # @tom = TermsOfMembership.find(params[:id])
    # if @tom.destroy
    #   redirect_to terms_of_memberships_url, notice: "#{@tom.name} (ID: #{@tom.id}) was successfully destroyed."
    # else
    #   flash[:error] = "#{@tom.name} (ID: #{@tom.id}) was not destroyed."
    #   redirect_to terms_of_memberships_url
    # end
  end

  def show
    @tom = TermsOfMembership.find(params[:id])
    my_authorize! :show, TermsOfMembership, @tom.club_id
    @email_templates = EmailTemplate.find_all_by_terms_of_membership_id(params[:id])
    @payment_gateway_configuration_development = PaymentGatewayConfiguration.find_by_club_id_and_mode(@current_club.id,'development')
    @payment_gateway_configuration_production = PaymentGatewayConfiguration.find_by_club_id_and_mode(@current_club.id,'production')
  end

end