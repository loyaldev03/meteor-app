class TransactionsController < ApplicationController
  before_filter :validate_club_presence
  before_filter :validate_user_presence

  def index
    my_authorize! :list, Transaction, @current_club.id
    respond_to do |format|
      format.html
      format.json { render json: TransactionsDatatable.new(view_context,@current_partner,@current_club,@current_user,@current_agent)}
    end
  end
end