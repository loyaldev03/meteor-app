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
        I18n.l(transaction.created_at, :format => :long),
        transaction.to_label, 
        number_to_currency(transaction.amount) ,
        transaction.can_be_refunded? ? number_to_currency(transaction.amount_available_to_refund) : '',
        transaction.response_transaction_id,
        transaction.can_be_refunded? ? link_to(I18n.t('refund'),
            @url_helpers.member_refund_path(@current_partner.prefix,@current_club.name,@current_member.visible_id, :transaction_id => transaction.id), 
            :class=>"btn btn-warning btn-mini") : '',
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

end    