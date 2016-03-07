class TermsOfMembershipsController < ApplicationController
  before_filter :validate_club_presence
  # before_filter :check_permissions

  def index
    my_authorize! :list, TermsOfMembership, @current_club.id
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: TermsOfMembershipDatatable.new(view_context,@current_partner,@current_club,nil,@current_agent) }
    end
  end

  def new
    my_authorize! :new, TermsOfMembership, @current_club.id
    @tom = TermsOfMembership.new
  end

  def create
    @tom = TermsOfMembership.new(params[:tom])
    my_authorize! :create, TermsOfMembership, @current_club.id
    prepare_tom_data_to_save(params)
    if @tom.save
      redirect_to terms_of_memberships_url, :notice => "Your Subscription Plan #{@tom.name} (ID: #{@tom.id}) was created succesfully"
    else
      flash.now[:error] = "There was an error while trying to save this subscription plan."
      render action: "new"
    end
  end

  def edit
    @tom = TermsOfMembership.find(params[:id])
    my_authorize! :edit, TermsOfMembership, @tom.club_id 
    if !@tom.can_update?
      flash[:error] = "Subscription Plan #{@tom.name} (ID: #{@tom.id}) can not be edited. It is being used"
      redirect_to terms_of_memberships_url
    end
  rescue ActiveRecord::RecordNotFound 
    flash[:error] = "Subscription Plan not found."
    redirect_to terms_of_memberships_url
  end

  def update
    @tom = TermsOfMembership.find(params[:id])
    my_authorize! :update, TermsOfMembership, @tom.club_id
    if @tom.can_update?
      prepare_tom_data_to_save(params)
      if @tom.save
        flash[:notice] = "Your Subscription Plan #{@tom.name} (ID: #{@tom.id}) was updated succesfully"
        redirect_to terms_of_memberships_url
      else
        flash.now[:error] = "Your Subscription Plan was not updated."
        render action: "edit"
      end
    else
      flash[:error] = "Subscription Plan #{@tom.name} (ID: #{@tom.id}) can not be edited. It is being used"
      redirect_to terms_of_memberships_url
    end
  end

  def destroy
    @tom = TermsOfMembership.find(params[:id])
    my_authorize! :destroy, TermsOfMembership, @tom.club_id
    if @tom.destroy
      flash[:notice] = "Subscription Plan #{@tom.name} (ID: #{@tom.id}) was successfully destroyed."
    else
      flash[:error] = "Subscription Plan #{@tom.name} (ID: #{@tom.id}) was not destroyed."
    end
    redirect_to terms_of_memberships_url
  rescue ActiveRecord::RecordNotFound 
    flash[:error] = "Subscription Plan not found."
    redirect_to terms_of_memberships_url
  end

  def show
    @tom = TermsOfMembership.find(params[:id])
    my_authorize! :show, TermsOfMembership, @tom.club_id
    @email_templates = @tom.email_templates.where(client: @tom.club.marketing_tool_client)
    @payment_gateway_configuration = @tom.club.payment_gateway_configuration
  rescue ActiveRecord::RecordNotFound 
    flash[:error] = "Subscription Plan not found."
    redirect_to terms_of_memberships_url
  end

  def resumed_information
    @tom = TermsOfMembership.find(params[:terms_of_membership_id])
    my_authorize! :show, TermsOfMembership, @tom.club_id
    render :partial => "resumed_information", :locals => { :tom => @tom }
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
      @tom.needs_enrollment_approval = post_data[:terms_of_membership][:needs_enrollment_approval]
      @tom.initial_fee = post_data[:initial_fee_amount]
      @tom.trial_period_amount = post_data[:trial_period_amount]
      @tom.provisional_days = post_data[:trial_period_lasting_time_span] == 'months' ? months_to_days(post_data[:trial_period_lasting].to_i) : post_data[:trial_period_lasting].to_i
      @tom.club_cash_installment_amount = post_data[:terms_of_membership][:club_cash_installment_amount]
      @tom.is_payment_expected = post_data[:is_payment_expected] == 'yes' ? true : false
      if @tom.is_payment_expected
        @tom.installment_amount = post_data[:installment_amount]
        @tom.installment_period = post_data[:installment_amount_days_time_span] == 'months' ? months_to_days(post_data[:installment_amount_days].to_i) : post_data[:installment_amount_days].to_i
      else
        @tom.installment_period = nil
        @tom.installment_amount = nil
        @tom.club_cash_installment_amount = nil
      end
      @tom.subscription_limits = post_data[:subscription_terms] == 'until_cancelled' ? 0 : (post_data[:subscription_terms_stop_billing_after_time_span] == 'months' ? months_to_days(post_data[:subscription_terms_stop_billing_after].to_i) : post_data[:subscription_terms_stop_billing_after].to_i)
      @tom.initial_club_cash_amount = post_data[:terms_of_membership][:initial_club_cash_amount]
      @tom.skip_first_club_cash = post_data[:terms_of_membership][:skip_first_club_cash]
      # Step 3
      case post_data[:if_cannot_bill_user]
      when 'cancel'
        @tom.if_cannot_bill = 'cancel'
        @tom.downgrade_tom_id = nil
        @tom.suspension_period = nil
      when 'suspend'
        @tom.if_cannot_bill = 'suspend'
        @tom.suspension_period = post_data[:if_cannot_bill_user_suspend_for_time_span] == 'months' ? months_to_days(post_data[:if_cannot_bill_user_suspend_for].to_i) : post_data[:if_cannot_bill_user_suspend_for].to_i
        @tom.downgrade_tom_id = nil
      when 'downgrade_to'
        @tom.if_cannot_bill = 'downgrade_tom'
        @tom.downgrade_tom_id = post_data[:downgrade_to_tom]
        @tom.suspension_period = nil
      end
      if post_data[:upgrade_to_tom] != ''
        @tom.upgrade_tom_id = post_data[:upgrade_to_tom]
        @tom.upgrade_tom_period = post_data[:upgrade_to_tom_days_time_span] == 'months' ? months_to_days(post_data[:upgrade_to_tom_days].to_i) : post_data[:upgrade_to_tom_days].to_i
      else 
        @tom.upgrade_tom_id = nil
        @tom.upgrade_tom_period = nil
      end
    end

    def months_to_days(months)
      months = months.to_i
      months > 0 ? (months * 30.4166667).to_i : 0
    end
end