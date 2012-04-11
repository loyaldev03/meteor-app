class ApplicationController < ActionController::Base
  before_filter :authenticate_user!
  protect_from_forgery

  private

  def set_routes_scopes
    unless params[:partner_prefix].nil?
      # @current_partner = Partner.find_by_prefix(params[:partner_prefix])
      @current_partner = Domain.first
    end
  end

end
