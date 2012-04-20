class MembersController < ApplicationController
  before_filter :validate_club_presence
  before_filter :setup_member, :only => [ :show ]

  def index
  end

  def show
  end

  private
    def setup_member
      @member = Member.find_by_visible_id_and_club_id(params[:id], @current_club.id)
    end
end
