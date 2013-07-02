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
        " <i class ='icon-folder-open help' rel= 'popover' data-toggle='modal' href='#myModal"+delayed_job.id.to_s+"' 
             style='cursor: pointer'></i>"+modal(delayed_job, delayed_job.handler),
        (delayed_job.last_error.blank? ? '' : delayed_job.last_error.truncate(50)+
        " <i class='icon-folder-open help' rel='popover' data-toggle='modal' href='#myLastErrorModal'"+delayed_job.id.to_s+"'
             style='cursor: pointer:'></i>"+modal(delayed_job, delayed_job.last_error)),
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
      delayed_jobs = delayed_jobs.where("prefix like :search or name like :search", search: "%#{params[:sSearch]}%")
    end
    delayed_jobs
  end

  def sort_column
    DelayedJob.datatable_columns[params[:iSortCol_0].to_i]
  end

  def modal(delayed_job, text)
    "<div id='myModal"+delayed_job.id.to_s+"' class='well modal hide' style='border: none;'>
      <div class='modal-header'>
        <a href='#' class='close'>&times;</a>
        <h3> "+I18n.t('activerecord.attributes.delayed_job.description')+"</h3>
      </div>
      <div class='modal-body'>"+text+" </div>
      <div class='modal-footer'> <a href='#' class='btn' data-dismiss='modal' >Close</a> </div>
    </div>"
  end
end    