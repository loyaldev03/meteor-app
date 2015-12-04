class OperationsDatatable < Datatable

private

  def total_records
    operations.count
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
        link_to("<i class='icon-zoom-in'>".html_safe, ((!@current_agent.can? :edit, Operation, @current_club.id) ? '#' : @url_helpers.operation_path(@current_partner.prefix,@current_club.name,@current_user.id,:id => operation.id)), :class => "btn btn-small", :disabled=>(!@current_agent.can? :edit, Operation, @current_club.id)),
      ]
    end
  end

  def operations
    @operations ||= fetch_operations
  end

  def fetch_operations
    operations = @current_user.operations.order("#{sort_column} #{sort_direction}").is_visible
    
    if params[:sSearch].present?
      if params[:sSearch] == 'billing'
        operations = operations.where("operation_type BETWEEN 100 and 199")
      elsif params[:sSearch] == 'profile'
        operations = operations.where("operation_type BETWEEN 200 and 299")
      elsif params[:sSearch] == 'communications'
        operations = operations.where("operation_type BETWEEN 300 and 399")
      elsif params[:sSearch] == 'fulfillments'
        operations = operations.where("operation_type BETWEEN 400 and 499")
      elsif params[:sSearch] == 'vip'
        operations = operations.where("operation_type BETWEEN 900 and 999")
      elsif params[:sSearch] == 'others'
        operations = operations.where("operation_type BETWEEN 1000 and 1099")
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
    "<div id='myModal#{operation.id.to_s}' class='modal hide fade' tabindex='-1'role='dialog' aria-labelledby='myModalLabel' aria-hidden='true'>
      <div class='modal-header'>
        <a href='#' class='close' data-dismiss='modal'>&times</a>
        <h3>Note</h3>
      </div>
      <div class='modal-body'>" + operation.notes.to_s + "</div>
      <div class='modal-footer'><a href='#' class='btn' data-dismiss='modal' >Close</a></div>
    </div>"
  end
  
end    