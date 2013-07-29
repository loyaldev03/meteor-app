class TermsOfMembershipDatatable < Datatable
private

  def total_records
    toms.find_all_by_club_id(@current_club.id).count
  end

  def total_entries
    toms.total_entries
  end

  def data
    toms.map do |tom|
      [
        tom.id,
        tom.name,
        tom.api_role,
        I18n.l(tom.created_at, :format => :dashed),
        get_agent_name(tom),
        (link_to(I18n.t(:show), @url_helpers.terms_of_membership_path(@current_partner.prefix, @current_club.name, tom.id), :class => 'btn btn-mini', :id => 'show') if @current_agent.can? :read, TermsOfMembership, @current_club.id)+
        (link_to(I18n.t(:edit), @url_helpers.edit_terms_of_membership_path(@current_partner.prefix, @current_club.name, tom.id), :class => 'btn btn-mini', :id => 'edit') if @current_agent.can? :edit, TermsOfMembership, @current_club.id)+
        (link_to(I18n.t(:destroy), @url_helpers.terms_of_membership_path(@current_partner.prefix, @current_club.name, tom.id), :method => :delete, :confirm => I18n.t("are_you_sure"), :id => 'destroy', :class => 'btn btn-mini btn-danger') if @current_agent.can? :delete, TermsOfMembership, @current_club.id)
      ]
    end
  end

  def toms
    @toms ||= fetch_toms
  end

  def fetch_toms
    toms = TermsOfMembership.where(:club_id => @current_club.id).order("#{sort_column} #{sort_direction}")
    toms = toms.page(page).per_page(per_page)
    if params[:sSearch].present?
      toms = toms.where("id like :search or name like :search", search: "%#{params[:sSearch]}%")
    end
    toms
  end

  def sort_column
    TermsOfMembership.datatable_columns[params[:iSortCol_0].to_i]
  end

  def get_agent_name(tom)
    begin
      tom.agent.username  
    rescue
      '(Not set)'
    end
  end

end
