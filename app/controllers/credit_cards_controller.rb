class CreditCardsController < ApplicationController
  require "exceptions"
	before_filter :validate_club_presence
	before_filter :validate_member_presence
  before_filter :check_authentification

  def new
    @credit_card = CreditCard.new
    @actual_credit_card = @current_member.active_credit_card
    @months = 1..12
    @years = Time.zone.now.year.upto(Time.zone.now.year+20).to_a
  end

  def create
    @credit_card = CreditCard.new(params[:credit_card])
    @credit_card.member_id = @current_member.id
    @months = 1..12
    @years = Time.zone.now.year.upto(Time.zone.now.year+20).to_a

    response = @current_member.update_credit_card_from_drupal(params[:credit_card], @current_agent)

    if response[:code] == Settings.error_codes.success
      @current_member.api_member.save!(force: true) rescue nil
      redirect_to show_member_path, notice: response[:message]
    else
      flash.now[:error] = "#{response[:message]} #{response[:errors].to_s}"
      render "new"
    end
  end

  def destroy
    @credit_card = CreditCard.find(params[:id])
    if @credit_card.destroy
      message = "Credit Card #{@credit_card.last_digits} was successfully destroyed"
      Auditory.audit(@current_agent, @credit_card, message, @current_member, Settings.operation_types.credit_card_deleted)
      redirect_to show_member_path, notice: message
    else
      error = @credit_card.errors.collect {|attr, message| "#{message}" }.join("")
      flash[:error] = "Credit Card #{@credit_card.last_digits} was not destroyed. #{error}"
      redirect_to show_member_path
    end
  end

  def activate
    CreditCard.transaction do 
      begin
        new_credit_card = CreditCard.find(params[:credit_card_id])
        new_credit_card.set_as_active!
        @current_member.api_member.save!(force: true) rescue nil
        redirect_to show_member_path, notice: "Credit card #{new_credit_card.last_digits} activated."
      rescue CreditCardDifferentGatewaysException
        flash[:error] = t('error_messages.credit_card_gateway_differs_from_current')
        redirect_to show_member_path
      rescue Exception => e
        Auditory.report_issue("CreditCardsController::activate", "#{e.to_s}\n\n#{$@[0..9] * "\n\t"}", { :params => params.inspect, :member => @current_member.inspect })
        flash[:error] = t('error_messages.airbrake_error_message')
        redirect_to show_member_path
        logger.error e.inspect
        raise ActiveRecord::Rollback
      end
    end
  end

  private
    def check_authentification
      my_authorize! :manage, CreditCard, @current_club.id
    end

end
