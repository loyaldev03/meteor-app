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
        agent_name(file),
        file.sent? ? "" : link_to('<i class="icon-file"></i>'.html_safe, @url_helpers.download_xls_fulfillments_path(@current_partner.prefix,@current_club.name,file.id, :only_in_progress => true), :class => "btn", :id=>"download_xls_#{file.id}"),
        link_to("View", @url_helpers.fulfillment_list_for_file_path(@current_partner.prefix,@current_club.name,file.id), :class => "btn"),
        file.status, 
        file.product,
        file.dates,
        file.fulfillments_processed,
        action_buttons_for_file(file)
      ]
    end
  end

  def files
    @files ||= fetch_files
  end

  def fetch_files
    files = @current_club.fulfillment_files.order("status ASC, created_at DESC")
    if params[:sSearch].present?
      files = files.where("id = :search", search: "#{params[:sSearch].gsub(/\D/,'')}")
    end

    files.page(page).per_page(per_page)
  end

  def agent_name(file)
    file.agent.present? ? file.agent.email : "(#{I18n.t('not_set')})"
  end

  def action_buttons_for_file(file)
    [
      if file.in_process?
        link_to(
          I18n.t('buttons.mark_as_packed'),
          @url_helpers.fulfillment_file_mark_as_packed_path(@current_partner.prefix, @current_club.name, file.id),
          class: 'btn btn-warning mark_as_packed',
          id: "mark_as_packed_#{file.id}",
          data: { confirm: I18n.t('activerecord.attributes.fulfillment_files.mark_as_packed_are_you_sure') }
        )
      end,
      if file.in_process? || file.packed?
        link_to(
          I18n.t('buttons.mark_as_sent'),
          @url_helpers.fulfillment_file_mark_as_sent_path(@current_partner.prefix, @current_club.name, file.id),
          class: 'btn btn-warning mark_as_sent',
          id: "mark_as_sent_#{file.id}",
          data: { confirm: I18n.t('activerecord.attributes.fulfillment_files.mark_as_sent_are_you_sure') }
        )
      end
    ].compact.join(' ')
  end
end     
