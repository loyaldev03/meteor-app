class DelayedJobsDatatable < Datatable

private

  def total_records
    DelayedJob.count
  end

  def total_entries
    delayed_jobs.total_entries
  end

  def data
    delayed_jobs.map do |delayed_job|
      [
        delayed_job.id,
        delayed_job.attempts,

        delayed_job.handler.truncate(75)+
        " <i class='icon-folder-open help' rel='popover' data-toggle='modal' href='#myModal"+delayed_job.id.to_s+"' 
             style='cursor: pointer'></i>"+modal("myModal"+delayed_job.id.to_s, delayed_job.handler, "handler"),

        (delayed_job.last_error.blank? ? '' : delayed_job.last_error.truncate(50)+
        " <i class='icon-folder-open help' rel='popover' data-toggle='modal' href='#myErrorModal"+delayed_job.id.to_s+"'
             style='cursor: pointer'></i>"+modal("myErrorModal"+delayed_job.id.to_s, delayed_job.last_error, "last_error")),
        I18n.l( delayed_job.run_at, :format => :dashed),
        I18n.l( delayed_job.created_at, :format => :dashed),
        link_to( I18n.t('buttons.reschedule'), @url_helpers.admin_delayed_job_reschedule_path(:id => delayed_job.id), 
                                              :class => 'btn btn-mini', :method => :post ) 
      ]
    end
  end

  def delayed_jobs
    @delayed_jobs ||= fetch_delayed_jobs
  end

  def fetch_delayed_jobs
    delayed_jobs = DelayedJob.order("#{sort_column} #{sort_direction}")
    delayed_jobs = delayed_jobs.page(page).per_page(per_page)
    if params[:sSearch].present?
      delayed_jobs = delayed_jobs.where("id like :search or handler like :search or last_error like :search", search: "%#{params[:sSearch]}%")
    end
    delayed_jobs
  end

  def sort_column
    DelayedJob.datatable_columns[params[:iSortCol_0].to_i]
  end

  def modal(modal_id, text, param)
    "<div id='"+modal_id+"' class='well modal hide' style='border: none;'>
      <div class='modal-header'>
        <a href='#' class='close' data-dismiss='modal'>&times;</a>
        <h3> "+I18n.t("activerecord.attributes.delayed_job.#{param}")+"</h3>
      </div>
      <div class='modal-body'>"+text+" </div>
      <div class='modal-footer'> <a href='#' class='btn' data-dismiss='modal' >Close</a> </div>
    </div>"
  end
end    