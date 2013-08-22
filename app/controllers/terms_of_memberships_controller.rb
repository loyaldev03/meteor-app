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
    prepare_tom_data_to_save(params)
    if @tom.save
      redirect_to terms_of_memberships_url, :notice => "Your Suscription Plan #{@tom.name} (ID: #{@tom.id}) was created succesfully"
    else
      render action: "new"
    end
  end

  def edit
    @tom = TermsOfMembership.find(params[:id])
    if !@tom.can_update_or_delete
      flash[:error] = "Suscription Plan #{@tom.name} (ID: #{@tom.id}) can not be edited. It is being used"
      redirect_to terms_of_memberships_url
    end
  end

  def update
    @tom = TermsOfMembership.find(params[:id])
    if @tom.can_update_or_delete
      prepare_tom_data_to_save(params)
      if @tom.save
        flash[:notice] = "Your Suscription Plan #{@tom.name} (ID: #{@tom.id}) was updated succesfully"
      else
        flash[:error] = "Your Suscription Plan #{@tom.name} (ID: #{@tom.id}) was not updated"
      end
    else
      flash[:error] = "Suscription Plan #{@tom.name} (ID: #{@tom.id}) can not be edited. It is being used"      
    end
    redirect_to terms_of_memberships_url
  end

  def destroy
    @tom = TermsOfMembership.find(params[:id])
    if @tom.destroy
      flash[:notice] = "Suscription Plan #{@tom.name} (ID: #{@tom.id}) was successfully destroyed."
    else
      flash[:error] = "Suscription Plan #{@tom.name} (ID: #{@tom.id}) was not destroyed."
    end
    redirect_to terms_of_memberships_url
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
      @tom.initial_fee = post_data[:initial_fee_amount]
      @tom.trial_period_amount = post_data[:trial_period_amount]
      @tom.provisional_days = post_data[:trial_period_lasting_time_span] == 'months' ? months_to_days(post_data[:trial_period_lasting].to_i) : post_data[:trial_period_lasting].to_i
      @tom.installment_amount = nil
      @tom.installment_period = nil
      @tom.is_payment_expected = post_data[:is_payment_expected] == 'yes' ? 1 : 0
      if @tom.is_payment_expected == 1
        @tom.installment_amount = post_data[:installment_amount]
        @tom.installment_period = post_data[:installment_amount_days_time_span] == 'months' ? months_to_days(post_data[:installment_amount_days].to_i) : post_data[:installment_amount_days].to_i
      end
      @tom.suscription_limits = post_data[:suscription_terms] == 'until_cancelled' ? 0 : (post_data[:suscription_terms_stop_billing_after_time_span] == 'months' ? months_to_days(post_data[:suscription_terms_stop_billing_after].to_i) : post_data[:suscription_terms_stop_billing_after].to_i)
      @tom.club_cash_amount = post_data[:club_cash_amount]
      # Step 3
      @tom.downgrade_tom_id = nil
      @tom.upgrade_tom_id = nil
      @tom.upgrade_tom_period = nil
      case post_data[:if_cannot_bill_member]
      when 'cancel'
        @tom.if_cannot_bill = 'cancel'
      when 'suspend'
        @tom.if_cannot_bill = 'suspend'
        @tom.suspension_period = post_data[:if_cannot_bill_member_suspend_for_time_span] == 'months' ? months_to_days(post_data[:if_cannot_bill_member_suspend_for].to_i) : post_data[:if_cannot_bill_member_suspend_for].to_i
      when 'downgrade_to'
        @tom.if_cannot_bill = 'downgrade_tom'
        @tom.downgrade_tom_id = post_data[:downgrade_to_tom]
      end
      if post_data[:upgrade_to_tom] != '' and post_data[:upgrade_to_tom_days].to_i > 0
        @tom.upgrade_tom_id = post_data[:upgrade_to_tom]
        @tom.upgrade_tom_period = post_data[:upgrade_to_tom_days_time_span] == 'months' ? months_to_days(post_data[:upgrade_to_tom_days].to_i) : post_data[:upgrade_to_tom_days].to_i
      end
    end

    def months_to_days(months)
      months = months.to_i
      months > 0 ? (months * 30.4166667).to_i : 0
    end
end