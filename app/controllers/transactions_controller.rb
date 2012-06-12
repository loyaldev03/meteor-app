class TransactionsController < ApplicationController
  before_filter :validate_club_presence
  before_filter :validate_member_presence

  def index
    respond_to do |format|
      format.html
      format.json { render json: TransactionsDatatable.new(view_context,@current_member,@current_club)}
    end
  end
end