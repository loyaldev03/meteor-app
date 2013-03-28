class TransactionsDatatable < Datatable

private
  def total_records
    @current_member.transactions.count
  end

  def total_entries
    transactions.total_entries
  end

  def data
    transactions.map do |transaction|
      [
        I18n.l(transaction.created_at, :format => :dashed),
        transaction.full_label.truncate(50)+
        " <i class ='icon-eye-open help' rel= 'popover' data-toggle='modal' href='#myModal"+transaction.id+"' 
             style='cursor: pointer'></i>"+modal(transaction), 
        number_to_currency(transaction.amount) ,
        transaction.can_be_refunded? ? number_to_currency(transaction.amount_available_to_refund) : '',
        transaction.response_transaction_id,
        transaction.last_digits,
        transaction.can_be_refunded? ? link_to(I18n.t('refund'),
            @url_helpers.member_refund_path(@current_partner.prefix,@current_club.name,@current_member.id, :transaction_id => transaction.id), 
            :class=>"btn btn-warning btn-mini", :id => 'refund' ,:disabled=>(!@current_agent.can? :refund, Transaction, @current_club.id)) : '',
      ]
    end
  end

  def transactions
    @transactions ||= fetch_transactions
  end

  def fetch_transactions
    transactions = Transaction.order("#{sort_column} #{sort_direction}").where('member_id' => @current_member)
    transactions = transactions.page(page).per_page(per_page)
    if params[:sSearch].present?
      transactions = transactions.where("transaction_type like :search or response_result like :search", search: "%#{params[:sSearch]}%")
    end
    transactions
  end

  def sort_column
    Transaction.datatable_columns[params[:iSortCol_0].to_i]
  end

  def modal(transaction)
    "<div id='myModal"+transaction.id+"' class='well modal hide' style='border: none;'>
      <div class='modal-header'>
        <a href='#' class='close'>&times;</a>
        <h3> "+I18n.t('activerecord.attributes.transaction.description')+"</h3>
      </div>
      <div class='modal-body'>"+transaction.full_label+" </div>
      <div class='modal-footer'> <a href='#' class='btn' data-dismiss='modal' >Close</a> </div>
    </div>"
  end
end    