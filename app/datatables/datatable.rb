class Datatable
  delegate :params, :h, :link_to, :number_to_currency, to: :@view
  
  def initialize(view,current_partner=nil,current_club =nil, current_user=nil, current_agent=nil)
    @view = view
    @current_partner = current_partner
    @current_club = current_club
    @current_user = current_user
    @current_agent = current_agent
    @url_helpers = Rails.application.routes.url_helpers
  end

  def as_json(options = {})
    {
      sEcho: params[:sEcho].to_i,
      iTotalRecords: total_records,
      iTotalDisplayRecords: total_entries,
      aaData: data
    }
  end
  
private

  def page
    params[:iDisplayStart].to_i/per_page + 1
  end

  def per_page
    params[:iDisplayLength].to_i > 0 ? params[:iDisplayLength].to_i : 10
  end

  def sort_direction
    params[:sSortDir_0] == "desc" ? "desc" : "asc"
  end
end    