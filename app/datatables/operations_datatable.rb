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
        operation.description.to_s.truncate(150) + note_icon(operation),
        operation.created_by.username,
        link_to("<i class='icon-zoom-in'>".html_safe, ((!@current_agent.can? :edit, Operation, @current_club.id) ? '#' : @url_helpers.operation_path(@current_partner.prefix,@current_club.name,@current_member.id,:id => operation.id)), :class => "btn btn-small", :disabled=>(!@current_agent.can? :edit, Operation, @current_club.id)),
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
        operations = Operation.where(["member_id = ? AND operation_type BETWEEN 100 and 199",@current_member.id]).order("#{sort_column} #{sort_direction}")    
      elsif params[:sSearch] == 'profile'
        operations = Operation.where(["member_id = ? AND operation_type BETWEEN 200 and 299",@current_member.id]).order("#{sort_column} #{sort_direction}")
      elsif params[:sSearch] == 'communications'
        operations = Operation.where(["member_id = ? AND operation_type BETWEEN 300 and 399",@current_member.id]).order("#{sort_column} #{sort_direction}")
      elsif params[:sSearch] == 'fulfillments'
        operations = Operation.where(["member_id = ? AND operation_type BETWEEN 400 and 499",@current_member.id]).order("#{sort_column} #{sort_direction}")        
      elsif params[:sSearch] == 'vip'
        operations = Operation.where(["member_id = ? AND operation_type BETWEEN 900 and 999",@current_member.id]).order("#{sort_column} #{sort_direction}")            
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
  
  def note_icon(operation)
    (operation.notes.to_s.length > 0 ? " <i class ='icon-comment help' rel= 'popover' data-toggle='modal' href='#myModal" + operation.id.to_s + "' style='cursor: pointer'></i>" + modal(operation) : '')
  end
  
  def modal(operation)
    "<div id='myModal" + operation.id.to_s + "' class='well modal hide' style='border: none;'>
      <div class='modal-header'>
        <a href='#' class='close'>&times;</a>
        <h3>Note</h3>
      </div>
      <div class='modal-body'>" + operation.notes.to_s + "</div>
      <div class='modal-footer'><a href='#' class='btn' data-dismiss='modal' >Close</a></div>
    </div>"
  end
  
end    