class OperationsDatatable < Datatable

private

  def total_records
    @current_member.operations.count
  end

  def total_entries
    operations.count
  end

  def data
    operations.map do |operation|
      [
        operation.id,
        I18n.l(operation.operation_date,:format => :dashed),
        #I couldnt make it work in another way. TODO: fix operation#show url.
        operation.description.html_safe, 
        operation.notes.to_s.truncate(42),
        operation.created_by.username,
        link_to("<i class='icon-zoom-in'>".html_safe, @url_helpers.operation_path(@current_partner.prefix,@current_club.name,@current_member.visible_id,:id => operation.id), :class => "btn btn-small"),
      ]
    end
  end

  def operations
    @operations ||= fetch_operations
  end

  def fetch_operations
    operations = Operation.order("#{sort_column} #{sort_direction}").where('member_id' => @current_member)
    
    if params[:sSearch].present?
      if params[:sSearch] == 'billing'
        search = [Settings.operation_types.enrollment_billing, Settings.operation_types.membership_billing,
                  Settings.operation_types.full_save, Settings.operation_types.change_next_bill_date,
                  Settings.operation_types.credit ]
        operations = Operation.where('member_id' => @current_member.id,'operation_type' => [search[0],search[1],search[2],search[3],search[4]]).order("#{sort_column} #{sort_direction}")
      elsif params[:sSearch] == 'communications'
        search = [Settings.operation_types.active_email, Settings.operation_types.prebill_email,
                  Settings.operation_types.cancellation_email, Settings.operation_types.refund_email]
        operations = Operation.where('member_id' => @current_member.id,'operation_type' => [search[0],search[1],search[2],search[3]]).order("#{sort_column} #{sort_direction}")
      elsif params[:sSearch] == 'profile'
        search = [Settings.operation_types.cancel, Settings.operation_types.future_cancel, Settings.operation_types.save_the_sale]
        operations = Operation.where('member_id' => @current_member.id,'operation_type' => [search[0],search[1],search[2]]).order("#{sort_column} #{sort_direction}")
      elsif params[:sSearch] == 'others'
        operations = Operation.where('member_id' => @current_member.id,'operation_type' => Settings.operation_types.others).order("#{sort_column} #{sort_direction}")
      elsif params[:sSearch] == 'all'
        operations = Operation.order("#{sort_column} #{sort_direction}").where('member_id' => @current_member)
      end
    end
    operations = operations.page(page).per_page(per_page)
    operations
  end

  def sort_column
    Operation.datatable_columns[params[:iSortCol_0].to_i]
  end

end    