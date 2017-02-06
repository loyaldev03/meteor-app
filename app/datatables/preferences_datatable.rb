class PreferencesDatatable < Datatable
private

  def total_records
    Preference.where(preference_group_id: params[:preference_group_id]).count
  end

  def total_entries
    preferences.total_entries
  end

  def data
    preferences.map do |preference|
      [
        preference.name,
        (link_to(I18n.t(:edit), '#', :class => 'btn btn-mini', data: { toggle: 'custom-remote-modal', name: preference.name, target: @url_helpers.edit_preference_group_preference_path(@current_partner.prefix, @current_club.name, params[:preference_group_id], preference.id) }) if @current_agent.can? :edit, Preference, @current_club.id).to_s+
        (link_to(I18n.t(:destroy), '#', 
                        :method => :delete,
                        :data => {:confirm => I18n.t("are_you_sure"), target: @url_helpers.preference_group_preference_path(@current_partner.prefix, @current_club.name, params[:preference_group_id], id: preference.id)},
                        :class => 'btn btn-mini btn-danger') if @current_agent.can? :destroy, Preference, @current_club.id).to_s
      ]
    end
  end

  def preferences
    @preferences ||= fetch_preferences
  end

  def fetch_preferences
    preferences = Preference.where(preference_group_id: params[:preference_group_id]).order("#{sort_column} #{sort_direction}").page(page).per_page(per_page)
    if params[:sSearch].present?
      preferences = preferences.where("name like :search", search: "%#{params[:sSearch]}%")
    end
    preferences
  end

  def sort_column
    Preference.datatable_columns[params[:iSortCol_0].to_i]
  end
end