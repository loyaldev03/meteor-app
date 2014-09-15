class ClubCashTransactionsDatatable < Datatable

private
  def total_records
    @current_user.club_cash_transactions.count
  end

  def total_entries
    club_cash_transactions.total_entries
  end

  def data
    club_cash_transactions.map do |club_cash_transaction|
      [
        club_cash_transaction.id,
        I18n.l(club_cash_transaction.created_at, :format => :dashed),
        club_cash_transaction.description,
        club_cash_transaction.amount
      ]
    end
  end

  def club_cash_transactions
    @club_cash_transactions ||= fetch_club_cash_transactions
  end

  def fetch_club_cash_transactions
    club_cash_transactions = ClubCashTransaction.order("#{sort_column} #{sort_direction}").where('user_id' => @current_user)
    club_cash_transactions = club_cash_transactions.page(page).per_page(per_page)
    if params[:sSearch].present?
      club_cash_transactions = club_cash_transactions.where("amount like :search or description like :search", search: "%#{params[:sSearch]}%")
    end
    club_cash_transactions
  end

  def sort_column
    ClubCashTransaction.datatable_columns[params[:iSortCol_0].to_i]
  end
end    