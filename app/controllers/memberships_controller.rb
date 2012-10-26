class MembershipsController < ApplicationController
  before_filter :validate_club_presence
  before_filter :validate_member_presence

  def index
    respond_to do |format|
      format.html
      format.json { render json: MembershipsDatatable.new(view_context,@current_partner,@current_club,@current_member,@current_agent)}
    end
  end
end