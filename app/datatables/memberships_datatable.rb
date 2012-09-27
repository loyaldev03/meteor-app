class MembershipsDatatable < Datatable

private
  def total_records
    @current_member.memberships.count
  end

  def total_entries
    memberships.total_entries
  end

  def data
    memberships.map do |membership|
      [ membership.id, 
        membership.status, 
        membership.terms_of_membership.to_label, 
        membership.join_date, 
        membership.cancel_date, 
        membership.quota
      ]
    end
  end

  def memberships
    @memberships ||= fetch_memberships
  end

  def fetch_memberships
    memberships = Membership.order("#{sort_column} #{sort_direction}").where('member_id' => @current_member)
    memberships.page(page).per_page(per_page)
  end

  def sort_column
    Membership.datatable_columns[params[:iSortCol_0].to_i]
  end

end    