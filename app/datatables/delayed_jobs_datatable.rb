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
        delayed_job.handler,
        delayed_job.last_error,
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
end    