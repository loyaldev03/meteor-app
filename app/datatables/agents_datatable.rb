class AgentsDatatable
  delegate :params, :h, :link_to, :number_to_currency, to: :@view

  def initialize(view)
    @view = view
  end

  def as_json(options = {})
    {
      sEcho: params[:sEcho].to_i,
      iTotalRecords: Agent.count,
      iTotalDisplayRecords: agents.total_entries,
      aaData: data
    }
  end

private

  def data
    agents.map do |agent|
      [
        link_to(agent.id, "/agents/#{agent.id}"),
        agent.email, 
        agent.username,
         if (agent.locked_at); I18n.l(agent.locked_at,:format=>:long) ;end,
        I18n.l(agent.created_at,:format=>:long),
        [link_to(I18n.t(:edit), "agents/#{agent.id}/edit", :class => 'btn btn-mini' ),
         link_to(I18n.t(:destroy), "agents/#{agent.id}", :method => :delete,
                        :confirm => I18n.t('.confirm', :default => I18n.t("helpers.links.confirm", :default => 'Are you sure?')),
                        :class => 'btn btn-mini btn-danger')]
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

  def page
    params[:iDisplayStart].to_i/per_page + 1
  end

  def per_page
    params[:iDisplayLength].to_i > 0 ? params[:iDisplayLength].to_i : 10
  end

  def sort_column
    columns = ['id', 'email', 'name', 'username', 'locked_at', 'created_at', 'actions']
    columns[params[:iSortCol_0].to_i]
  end

  def sort_direction
    params[:sSortDir_0] == "desc" ? "desc" : "asc"
  end
end    