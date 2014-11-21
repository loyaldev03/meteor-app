class TransactionsDatatable < Datatable

private
  def total_records
    @current_user.transactions.count
  end

  def total_entries
    transactions.total_entries
  end

  def data
    transactions.map do |transaction|
      [
        I18n.l(transaction.created_at, :format => :dashed),
        transaction_description(transaction).truncate(75) + 
          (transaction_description(transaction).length > 75 ? " <i class ='icon-eye-open help' rel= 'popover' data-toggle='modal' href='#myModal" + transaction.id.to_s + "' style='cursor: pointer'></i>" + modal(transaction) : ''), 
        number_to_currency(transaction.amount) ,
        transaction.can_be_refunded? ? number_to_currency(transaction.amount_available_to_refund) : '',
        transaction.gateway + " " + transaction.response_transaction_id.to_s,
        transaction.last_digits,
        transaction.can_be_refunded? ? link_to(I18n.t('refund'),
            @url_helpers.user_refund_path(@current_partner.prefix,@current_club.name,@current_user.id, :transaction_id => transaction.id), 
            :class=>"btn btn-warning btn-mini", :id => 'refund' ,:disabled=>(!@current_agent.can? :refund, Transaction, @current_club.id)) : '',
      ]
    end
  end

  def transactions
    @transactions ||= fetch_transactions
  end

  def fetch_transactions
    transactions = Transaction.order("#{sort_column} #{sort_direction}").where('user_id' => @current_user).includes(:user)
    transactions = transactions.page(page).per_page(per_page)
    if params[:sSearch].present?
      transactions = transactions.where("transaction_type like :search or response_result like :search", search: "%#{params[:sSearch]}%")
    end
    transactions
  end

  def transaction_description(transaction)
    # if @current_agent.has_role_with_club? 'representative', @current_club.id or @current_agent.has_role_with_club? 'supervisor', @current_club.id
    if @current_agent.can? :see_nice, Transaction, @current_club.id
      begin
        I18n.t('activerecord.attributes.transaction.transaction_types_messages.type_' + transaction.operation_type.to_s) + ' - ' + transaction.response_result.to_s
      rescue
        transaction.response_result.to_s
      end
    else
      transaction.full_label
    end
  end

  def sort_column
    Transaction.datatable_columns[params[:iSortCol_0].to_i]
  end

  def modal(transaction)
    "<div id='myModal" + transaction.id.to_s + "' class='well modal hide' style='border: none;'>
      <div class='modal-header'>
        <a href='#' class='close'>&times;</a>
        <h3> "+I18n.t('activerecord.attributes.transaction.description')+"</h3>
      </div>
      <div class='modal-body'>" + transaction_description(transaction) + " </div>
      <div class='modal-footer'> <a href='#' class='btn' data-dismiss='modal' >Close</a> </div>
    </div>"
  end
end    