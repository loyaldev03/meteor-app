class ClubCashTransactionsController < ApplicationController
  before_filter :validate_club_presence
  before_filter :validate_user_presence

  def index
  	my_authorize! :list, ClubCashTransaction, @current_club.id
    respond_to do |format|
      format.html
      format.json { render json: ClubCashTransactionsDatatable.new(view_context,@current_partner,@current_club,@current_user,@current_agent)}
    end
  end
end