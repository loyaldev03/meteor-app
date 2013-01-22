class FulfillmentFilesDatatable < Datatable

private
  def total_records
    FulfillmentFile.count
  end

  def total_entries
    files.total_entries
  end

  def data
    files.map do |file|
      [ 
        file.id, 
        file.status, 
        file.product
      ]
    end
  end

  def files
    @files ||= fetch_files
  end

  def fetch_files
    files = FulfillmentFile.order("#{sort_column} #{sort_direction}").where('agent_id' => @current_agent)
    files.page(page).per_page(per_page)
  end

  def sort_column
    FulfillmentFile.datatable_columns[params[:iSortCol_0].to_i]
  end

end    