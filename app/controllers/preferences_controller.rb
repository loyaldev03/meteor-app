class PreferencesController < ApplicationController
  before_filter :validate_club_presence
  before_filter :load_preference, only: [:edit, :update, :destroy]

  def index
    @preference = preference_group.preferences.new
    my_authorize! :list, Preference, @preference_group.club_id
    flash.now['alert'] = I18n.t('preference_management_notification')
    respond_to do |format|
      format.html
      format.json { render json: PreferencesDatatable.new(view_context, current_partner, current_club, current_user, current_agent)}
    end
  end

  def create
    my_authorize! :create, Preference, preference_group.club_id
    @preference = Preference.new params.require(:preference).permit(:name)
    @preference.preference_group_id = preference_group.id
    if @preference.save
      render json: { success: true, message: "Preference #{@preference.name} added successfully." }
    else
      render json: { success: false, message: "Preference was not added. #{@preference.errors.messages}" }
    end 
  end

  def edit
    my_authorize! :edit, Preference, @preference.preference_group.club_id
    render partial: 'edit'
  end

  def update
    my_authorize! :update, Preference, @preference.preference_group.club_id
    if @preference.update params.require(:preference).permit(:name)
      render json: { success: true, message: "Preference updated successfully." }
    else
      render json: { success: false, message: "Prefernece was not updated. #{@preference.errors.messages}" }
    end
  end

  def destroy
    my_authorize! :destroy, Preference, @preference.preference_group.club_id
    if @preference.destroy
      render json: { success: true, message: "Preference was successfully deleted." }
    else
      render json: { success: false, message: "Preference was not deleted." }
    end
  end

  private

  def load_preference
    @preference = Preference.find(params[:id])
  end

  def preference_group
    @preference_group ||= PreferenceGroup.find(params[:preference_group_id])
  end

end