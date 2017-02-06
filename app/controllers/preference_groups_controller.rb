class PreferenceGroupsController < ApplicationController
  before_filter :validate_club_presence

  def index
    my_authorize! :list, PreferenceGroup, current_club.id
    respond_to do |format|
      format.html
      format.json { render json: PreferenceGroupsDatatable.new(view_context, current_partner, current_club, current_user, current_agent)}
    end 
  end

  def show
    @preference_group = PreferenceGroup.find(params[:id])
    my_authorize! :read, PreferenceGroup, @preference_group.club_id
  end

  def new
    my_authorize! :new, PreferenceGroup, current_club.id
    @preference_group = PreferenceGroup.new(club_id: current_club.id)
  end

  def create
    my_authorize! :create, PreferenceGroup, current_club.id
    @preference_group = current_club.preference_groups.new params.require(:preference_group).permit(:name, :code, :add_by_default)
    if @preference_group.save
      redirect_to preference_group_path(partner_prefix: current_partner.prefix, club_prefix: current_club.name, id: @preference_group), notice: "Preference Group was successfully created."
    else
      render :new
    end
  end

  def edit
    @preference_group = PreferenceGroup.find(params[:id])
    my_authorize! :edit, PreferenceGroup, @preference_group.club_id
  end

  def update
    @preference_group = PreferenceGroup.find(params[:id])
    my_authorize! :update, PreferenceGroup, @preference_group.club_id

    if @preference_group.update params.require(:preference_group).permit(:name, :add_by_default)
      redirect_to preference_group_path(partner_prefix: current_partner.prefix, club_prefix: current_club.name, id: @preference_group), notice: "Preference Group was successfully updated."
    else
      render :edit
    end
  end

end