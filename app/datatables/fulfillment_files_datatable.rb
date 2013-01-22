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
        I18n.l(file.created_at.to_date),
        link_to('<i class="icon-file"></i>'.html_safe, @url_helpers.download_xls_fulfillments_path(@current_partner.prefix,@current_club.name,file.id), :class => "btn"),
        link_to("View", @url_helpers.fulfillment_list_for_file_path(@current_partner.prefix,@current_club.name,file.id), :class => "btn"),
        file.status, 
        file.product,
        file.dates,
        file.fulfillments_processed,
        (file.sent? ? '' : link_to("Mark as sent", @url_helpers.fulfillment_file_mark_as_sent_path(@current_partner.prefix,@current_club.name,file.id), :class => "btn btn-warning", :confirm => "Are you sure you want to mark all the fulfillments that are in progress as sent?"))
      ]
    end
  end

  def files
    @files ||= fetch_files
  end

  def fetch_files
    files = FulfillmentFile.order("status ASC, created_at DESC").where('agent_id' => @current_agent)
    files.page(page).per_page(per_page)
  end
end    