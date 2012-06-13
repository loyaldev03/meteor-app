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
        link_to(agent.id, @url_helpers.admin_agent_path(agent)),
        agent.email, 
        agent.username,
        if (agent.locked_at); I18n.l(agent.locked_at,:format=>:long) ;end,
        I18n.l(agent.created_at,:format=>:long),
        link_to(I18n.t(:edit), @url_helpers.edit_admin_agent_path(agent), :class => 'btn btn-mini' )+' '+
        link_to(I18n.t(:destroy), @url_helpers.admin_agent_path(agent), :method => :delete,
                        :confirm => I18n.t('.confirm', :default => I18n.t("helpers.links.confirm", :default => 'Are you sure?')),
                        :class => 'btn btn-mini btn-danger')
      ]
    end
  end

  def agents
    @agents ||= fetch_agents
  end

  def fetch_agents
    agents = Agent.order("#{sort_column} #{sort_direction}")
    agents = agents.page(page).per_page(per_page)
    if params[:sSearch].present?
      agents = agents.where("id like :search or email like :search or username like :search", search: "%#{params[:sSearch]}%")
    end
    agents
  end

  def sort_column
    Agent.datatable_columns[params[:iSortCol_0].to_i]
  end
end    