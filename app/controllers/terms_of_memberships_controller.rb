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
  end

  def create
    @tom = TermsOfMembership.new(params[:tom])
    # @tom.club_id = @current_club.id
    prepare_tom_data_to_save(params)
    if @tom.save
      redirect_to terms_of_memberships_url, notice: "Your Suscription Plan #{@tom.name} (ID: #{@tom.id}) was created Succesfully"
    else
      render action: "new"
    end
  end

  def destroy
    @tom = TermsOfMembership.find(params[:id])
    if @tom.destroy
      redirect_to terms_of_memberships_url, notice: "Suscription Plan #{@tom.name} (ID: #{@tom.id}) was successfully destroyed."
    else
      flash[:error] = "Suscription Plan #{@tom.name} (ID: #{@tom.id}) was not destroyed."
      redirect_to terms_of_memberships_url
    end
  end

  def show
    @tom = TermsOfMembership.find(params[:id])
    my_authorize! :show, TermsOfMembership, @tom.club_id
    @email_templates = EmailTemplate.find_all_by_terms_of_membership_id(params[:id])
    @payment_gateway_configuration_development = PaymentGatewayConfiguration.find_by_club_id_and_mode(@current_club.id,'development')
    @payment_gateway_configuration_production = PaymentGatewayConfiguration.find_by_club_id_and_mode(@current_club.id,'production')
  end

  private
    def prepare_tom_data_to_save(post_data)
      @tom.club_id = @current_club.id
      @tom.agent_id = @current_agent.id
      
      # Step #1
      @tom.name = post_data[:terms_of_membership][:name]
      @tom.api_role = post_data[:terms_of_membership][:api_role]
      @tom.description = post_data[:terms_of_membership][:description]

      # Step 2
      @tom.initial_fee = post_data[:initial_fee]
      @tom.trial_period_amount = post_data[:trial_period_amount]
      @tom.provisional_days = post_data[:trial_period_lasting_time_span] == 'months' ? months_to_days(post_data[:trial_period_lasting]) : post_data[:trial_period_lasting]
      @tom.is_payment_expected = post_data[:is_payment_expected] == 'yes' ? 1 : 0
      @tom.installment_amount = post_data[:installment_amount]
      @tom.installment_period = post_data[:installment_amount_days_time_span] == 'months' ? months_to_days(post_data[:installment_amount_days]) : post_data[:installment_amount_days]
      @tom.suscription_terms = 
        if post_data[:suscription_terms] == 'until_cancelled'
          0
        else
          post_data[:suscription_terms_stop_billing_after_time_span] == 'months' ? 
            months_to_days(post_data[:suscription_terms_stop_billing_after]) : post_data[:suscription_terms_stop_billing_after]
        end
      
      # Step 3

      
    end

    def months_to_days(months)
      if months > 0
        if months % 12 == 0
          months / 12 * 365
        else
          months * 30
        end
      else
        0
      end
    end
end