class CreditCardsController < ApplicationController
	before_filter :validate_club_presence
	before_filter :validate_member_presence
  before_filter :check_authentification

  def new
    @credit_card = CreditCard.new
    @actual_credit_card = @current_member.active_credit_card
  end

  def create
    @credit_card = CreditCard.new(params[:credit_card])
    @credit_card.member_id = @current_member.id

    response = @current_member.update_credit_card_from_drupal(params[:credit_card], @current_agent)

    if response[:code] == Settings.error_codes.success
      @current_member.api_member.save!(force: true) rescue nil
      redirect_to show_member_path(:id => @current_member), notice: response[:message]
    else
      flash.now[:error] = "#{response[:message]} #{response[:errors].to_s}"
      render "new"
    end
  end

  def activate
  	new_credit_card = CreditCard.find(params[:credit_card_id])
    new_credit_card.set_as_active!
    @current_member.api_member.save!(force: true) rescue nil
    message = "Credit card #{new_credit_card.last_digits} activated."
    Auditory.audit(@current_agent, new_credit_card, message, @current_member)
    redirect_to show_member_path(:id => @current_member), notice: message
  rescue Exception => e
    Airbrake.notify(:error_class => "CreditCardsController::activate", :error_message => "#{e.to_s}\n\n#{$@[0..9] * "\n\t"}", :parameters => { :params => params.inspect })
    redirect_to show_member_path(:id => @current_member), error: e
  end

  private
    def check_authentification
      my_authorize! :manage, CreditCard, @current_club.id
    end

end
