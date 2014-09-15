class MembershipsDatatable < Datatable

private
  def total_records
    @current_user.memberships.count
  end

  def total_entries
    memberships.total_entries
  end

  def data
    memberships.map do |membership|
      [ membership.id, 
        membership.status, 
        membership.terms_of_membership.name, 
        (I18n.l(membership.join_date, :format => :only_date) if membership.join_date), 
        (I18n.l(membership.cancel_date, :format => :only_date) if membership.cancel_date)
      ]
    end
  end

  def memberships
    @memberships ||= fetch_memberships
  end

  def fetch_memberships
    memberships = Membership.order("#{sort_column} #{sort_direction}").where('user_id' => @current_user)
    memberships.page(page).per_page(per_page)
  end

  def sort_column
    Membership.datatable_columns[params[:iSortCol_0].to_i]
  end

end    