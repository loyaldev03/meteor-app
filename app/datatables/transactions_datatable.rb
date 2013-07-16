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
        transaction_description(transaction).truncate(75) + 
          (transaction_description(transaction).length > 75 ? " <i class ='icon-eye-open help' rel= 'popover' data-toggle='modal' href='#myModal" + transaction.id + "' style='cursor: pointer'></i>" + modal(transaction) : ''), 
        number_to_currency(transaction.amount) ,
        transaction.can_be_refunded? ? number_to_currency(transaction.amount_available_to_refund) : '',
        transaction.gateway + " " + transaction.response_transaction_id.to_s,
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
    transactions = Transaction.order("#{sort_column} #{sort_direction}").where('member_id' => @current_member).includes(:member)
    transactions = transactions.page(page).per_page(per_page)
    if params[:sSearch].present?
      transactions = transactions.where("transaction_type like :search or response_result like :search", search: "%#{params[:sSearch]}%")
    end
    transactions
  end

  def transaction_description(transaction)
    description = case transaction.operation_type
      when 100
        I18n.t('activerecord.attributes.transaction.transaction_types_messages.enrollment_billing')
      when 101
        I18n.t('activerecord.attributes.transaction.transaction_types_messages.membership_billing')
      when 104
        I18n.t('activerecord.attributes.transaction.transaction_types_messages.credit')
      when 105
        I18n.t('activerecord.attributes.transaction.transaction_types_messages.membership_billing_without_decline_strategy')
      when 106
        I18n.t('activerecord.attributes.transaction.transaction_types_messages.membership_billing_hard_decline')
      when 107
        I18n.t('activerecord.attributes.transaction.transaction_types_messages.membership_billing_soft_decline')
      when 108
        I18n.t('activerecord.attributes.transaction.transaction_types_messages.credit_error')
      when 110
        I18n.t('activerecord.attributes.transaction.transaction_types_messages.chargeback')
      when 111
        I18n.t('activerecord.attributes.transaction.transaction_types_messages.error_on_enrollment_billing')
      when 112
        I18n.t('activerecord.attributes.transaction.transaction_types_messages.no_recurrent_billing')
      when 113
        I18n.t('activerecord.attributes.transaction.transaction_types_messages.no_recurrent_billing_with_error')
      when 114
        I18n.t('activerecord.attributes.transaction.transaction_types_messages.membership_billing_hard_decline_by_limit')
      when 115
        I18n.t('activerecord.attributes.transaction.transaction_types_messages.downgraded_because_of_hard_decline')
      when 116
        I18n.t('activerecord.attributes.transaction.transaction_types_messages.downgraded_because_of_hard_decline_by_limit')
      when 117
        I18n.t('activerecord.attributes.transaction.transaction_types_messages.membership_billing_without_decline_strategy_limit')
      when 118
        I18n.t('activerecord.attributes.transaction.transaction_types_messages.membership_manual_cash_billing')
      when 119
        I18n.t('activerecord.attributes.transaction.transaction_types_messages.membership_manual_check_billing')
      when 203
        I18n.t('activerecord.attributes.transaction.transaction_types_messages.recovery')
      when 206
        I18n.t('activerecord.attributes.transaction.transaction_types_messages.enrollment_needs_approval')
      else ''
    end
    description = (description.length > 0 ? description + ' - ' + transaction.response_result : transaction.response_result)
  end

  def sort_column
    Transaction.datatable_columns[params[:iSortCol_0].to_i]
  end

  def modal(transaction)
    "<div id='myModal" + transaction.id + "' class='well modal hide' style='border: none;'>
      <div class='modal-header'>
        <a href='#' class='close'>&times;</a>
        <h3> "+I18n.t('activerecord.attributes.transaction.description')+"</h3>
      </div>
      <div class='modal-body'>" + transaction_description(transaction) + " </div>
      <div class='modal-footer'> <a href='#' class='btn' data-dismiss='modal' >Close</a> </div>
    </div>"
  end
end    