class PreferenceGroupsDatatable < Datatable
private

  def total_records
    PreferenceGroup.where(club_id: @current_club.id).count
  end

  def total_entries
    preference_groups.total_entries
  end

  def data
    preference_groups.map do |preference_group|
      [
        preference_group.id,
        preference_group.name,
        preference_group.code,
        preference_group.add_by_default ? 'Yes' : 'No',
        (link_to(I18n.t(:show), @url_helpers.preference_group_path(@current_partner.prefix, @current_club.name, preference_group.id), :class => 'btn btn-mini', :id => 'show') if @current_agent.can? :read, PreferenceGroup, @current_club.id).to_s+
        (link_to(I18n.t(:edit), @url_helpers.edit_preference_group_path(@current_partner.prefix, @current_club.name, preference_group.id), :class => 'btn btn-mini', :id => 'show') if @current_agent.can? :edit, PreferenceGroup, @current_club.id).to_s+
        (link_to(I18n.t('activerecord.model.preferences'), @url_helpers.preference_group_preferences_path(@current_partner.prefix, @current_club.name, preference_group.id), :class => 'btn btn-mini', :id => 'show') if @current_agent.can? :list, Preference, @current_club.id).to_s
      ]
    end
  end

  def preference_groups
    @preference_groups ||= fetch_preference_groups
  end

  def fetch_preference_groups
    preference_groups = PreferenceGroup.where(:club_id => @current_club.id).page(page).per_page(per_page)
    if params[:sSearch].present?
      preference_groups = preference_groups.where("name like :search or code like :search", search: "%#{params[:sSearch]}%")
    end
    preference_groups
  end

  def sort_column
    PreferenceGroup.datatable_columns[params[:iSortCol_0].to_i]
  end
end