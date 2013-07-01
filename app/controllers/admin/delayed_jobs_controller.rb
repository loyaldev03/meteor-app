class Admin::DelayedJobsController < ApplicationController

	def index
		respond_to do |format|
			format.html
			format.json { render json: DelayedJobsDatatable.new(view_context,nil,nil,nil,@current_agent) }
		end
	end

	def reschedule
		if request.post?
			delayed_job = DelayedJob.find params[:delayed_job_id]
			if delayed_job.reschedule
				flash.now[:notice] = "Re-schedule job delayed_job.id"
			else
				flash.now[:error] = "Could not re-schedule #{delayed_job.errors.to_s}"
			end
			render :index
		end
	end
end