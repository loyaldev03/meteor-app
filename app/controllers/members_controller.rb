class MembersController < ApplicationController
  before_filter :validate_club_presence

  def index
  end

  def create
    # TODO: this method must set created_by = current_user.id
  end
end
