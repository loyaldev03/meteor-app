class AgentsDatatable < Datatable


private

  def total_records
    Agent.count
  end

  def total_entries
    agents.total_entries
  end

  def data
    agents.map do |agent|
      [
        agent.id,
        agent.email, 
        agent.username,
        I18n.l(agent.created_at,:format=>:long),
        (link_to(I18n.t(:show), @url_helpers.admin_agent_path(agent), :class => 'btn btn-mini') if @current_agent.is_admin?).to_s+
        (link_to(I18n.t(:edit), @url_helpers.edit_admin_agent_path(agent), :class => 'btn btn-mini') if @current_agent.is_admin?).to_s+
        (link_to(I18n.t(:destroy), @url_helpers.admin_agent_path(agent), 
                        :method => :delete,
                        :data => {confirm: 'Are you sure?'}, 
                        :class => 'btn btn-mini btn-danger') if @current_agent.is_admin?).to_s
      ]
    end
  end

  def agents
    @agents ||= fetch_agents
  end

  def fetch_agents
    agents = if @current_agent.has_global_role?
      Agent.order("#{sort_column} #{sort_direction}")
    else
      Agent.joins(:club_roles).where("club_id in (?)", @current_agent.clubs_related_id_list("admin")).order("#{sort_column} #{sort_direction}").group("agents.id")
    end
    agents = agents.page(page).per_page(per_page)
    if params[:sSearch].present?
      agents = agents.where("agents.id like :search or email like :search or username like :search", search: "%#{params[:sSearch]}%")
    end
    agents
  end

  def sort_column
    Agent.datatable_columns[params[:iSortCol_0].to_i]
  end
end    