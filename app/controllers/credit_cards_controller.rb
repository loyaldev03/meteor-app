class CreditCardsController < ApplicationController
	before_filter :validate_club_presence
	before_filter :validate_user_presence
  before_filter :check_authentification

  def new
    @credit_card          = CreditCard.new
    @actual_credit_card   = current_user.active_credit_card
    @terms_of_memberships = current_club.terms_of_memberships.select(:id, :name).where.not(id: current_user.terms_of_membership_id)
    @months               = 1..12
    @years                = Time.zone.now.year.upto(Time.zone.now.year+20).to_a
  end

  def create
    response              = current_user.update_credit_card_from_drupal(credit_card_params , @current_agent)
    if response[:code] == Settings.error_codes.success
      membership_update_response = if params[:terms_of_membership_id].present?
        current_user.change_terms_of_membership(params[:terms_of_membership_id], "Rollback to previous Membership", Settings.operation_types.membership_and_credit_card_update, current_agent, false, nil, { utm_campaign: Membership::CS_UTM_CAMPAIGN, utm_medium: Membership::CS_UTM_MEDIUM })
      end
      begin
        current_user.api_user.save!(force: true)
      rescue
        Auditory.report_issue("CreditCardsController::create - Could not sync user with Drupal", $!)
      end
      redirect_to show_user_path, notice: response[:message] + (membership_update_response[:message] if membership_update_response).to_s
    else
      flash.now[:error] = "#{response[:message]} #{response[:errors].to_s}"
      @credit_card          = CreditCard.new credit_card_params
      @terms_of_memberships = current_club.terms_of_memberships.select(:id, :name).where.not(id: current_user.terms_of_membership_id)
      @months               = 1..12
      @years                = Time.zone.now.year.upto(Time.zone.now.year+20).to_a
      render "new"
    end
  end

  def destroy
    @credit_card = CreditCard.find(params[:id])
    if @credit_card.destroy
      message = "Credit Card #{@credit_card.last_digits} was successfully destroyed"
      Auditory.audit(@current_agent, @credit_card, message, @current_user, Settings.operation_types.credit_card_deleted)
      redirect_to show_user_path, notice: message
    else
      error = @credit_card.errors.collect {|attr, message| "#{message}" }.join("")
      flash[:error] = "Credit Card #{@credit_card.last_digits} was not destroyed. #{error}"
      redirect_to show_user_path
    end
  end

  def activate
    new_credit_card = CreditCard.find(params[:credit_card_id])
    success = false
    CreditCard.transaction do 
      begin
        new_credit_card.set_as_active!
        success = true
      rescue CreditCardDifferentGatewaysException
        flash[:error] = t('error_messages.credit_card_gateway_differs_from_current')
        redirect_to show_user_path
      rescue Exception => e
        Auditory.report_issue("CreditCardsController::activate", e)
        flash[:error] = t('error_messages.airbrake_error_message')
        redirect_to show_user_path
        logger.error e.inspect
        raise ActiveRecord::Rollback
      end
    end
    if success
      begin
        current_user.api_user.save!(force: true)
      rescue 
        Auditory.report_issue("CreditCardsController::activate - Could not sync user with Drupal", $!)
      end
      redirect_to show_user_path, notice: "Credit card #{new_credit_card.last_digits} activated."
    end
  end

  private
    def check_authentification
      my_authorize! :manage, CreditCard, @current_club.id
    end

    def credit_card_params
      params.require(:credit_card).permit(:number, :expire_month, :expire_year)
    end
end
