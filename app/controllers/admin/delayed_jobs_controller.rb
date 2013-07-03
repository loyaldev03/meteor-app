class Admin::DelayedJobsController < ApplicationController
  authorize_resource :delayed_job

	def index
		respond_to do |format|
			format.html
			format.json { render json: DelayedJobsDatatable.new(view_context,nil,nil,nil,@current_agent) }
		end
	end

	def reschedule
		if request.post?
			delayed_job = DelayedJob.find params[:id]
			if delayed_job.reschedule
				flash.now[:notice] = "Re-scheduled job #{delayed_job.id}"
			else
				flash.now[:error] = "Could not re-schedule #{delayed_job.errors.to_s}"
			end
			render :index
		end
  rescue ActiveRecord::RecordNotFound
    flash.now[:error] = "Delayed job not found"
		render :index
  rescue Exception => e
    Auditory.report_issue("Delayed job re-schedule not successful", e, { :delayed_job => delayed_job.inspect })
		flash.now[:error] = I18n.t('error_messages.airbrake_error_message')
		render :index
	end
end