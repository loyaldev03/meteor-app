class FulfillmentsController < ApplicationController
  before_filter :validate_club_presence

  def index
    respond_to do |format|
      format.html 
      format.js 
    end
  end
  def report
  	redirect_to fulfillments_path(@current_partner.prefix,@current_club.name)
  end
end