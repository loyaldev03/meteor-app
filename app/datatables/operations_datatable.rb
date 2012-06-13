class OperationsDatatable < Datatable

  def initialize(view,current_member,current_partner,current_club,filter)
    @view = view
    @url_helpers = Rails.application.routes.url_helpers
    @current_member = current_member
    @current_partner = current_partner
    @current_club = current_club
    @filter = filter
  end

private

  def total_records
    @current_member.operations.count
  end

  def total_entries
    operations.total_entries
  end

  def data
    operations.map do |operation|
      [
        I18n.l(operation.operation_date,:format => :long),
        #I couldnt make it work in another way. TODO: fix operation#show url.
        link_to(operation.description.truncate(50), "#{@current_member.visible_id}/operations/#{operation.id}"), 
        operation.notes,
        operation.created_by.username
      ]
    end
  end

  def operations
    @operations ||= fetch_operations
  end

  def fetch_operations
    if @filter == 'billing'
        search = [Settings.operation_types.enrollment_billing, Settings.operation_types.membership_billing,
                  Settings.operation_types.full_save, Settings.operation_types.change_next_bill_date,
                  Settings.operation_types.credit ]
        operations = Operation.order("#{sort_column} #{sort_direction}").where(["(operation_type in(?,?,?,?,?)) AND member_id like ?",
                      search[0],search[1],search[2],search[3],search[4],'%'+@current_member.id+'%'])
      elsif @filter == 'communications'
        search = [Settings.operation_types.active_email, Settings.operation_types.prebill_email,
                  Settings.operation_types.cancellation_email, Settings.operation_types.refund_email]
        operations = Operation.order("#{sort_column} #{sort_direction}").where(["(operation_type in(?,?,?,?)) AND member_id like ?",
                      search[0],search[1],search[2],search[3],'%'+@current_member.id+'%'])
      elsif @filter == 'profile'
        search = [Settings.operation_types.cancel, Settings.operation_types.future_cancel,
                  Settings.operation_types.save_the_sale]
        operations = Operation.order("#{sort_column} #{sort_direction}").where("(operation_type in(?,?,?)) AND member_id like ?",
                      search[0],search[1],search[2],'%'+@current_member.id+'%')
      elsif @filter == 'others'
        operations = Operation.order("#{sort_column} #{sort_direction}").where("operation_type like ? AND member_id like ?",
                      Settings.operation_types.others,'%'+@current_member.id+'%')
      else
        operations = Operation.order("#{sort_column} #{sort_direction}").where('member_id' => @current_member)
    end
    operations = operations.page(page).per_page(per_page)
    if params[:sSearch].present?
      operations = operations.where("description like :search", search: "%#{params[:sSearch]}%")
    end
    operations
  end

  def sort_column
    columns = ['operation_date', 'description', 'notes', 'created_by']
    columns[params[:iSortCol_0].to_i]
  end

end    