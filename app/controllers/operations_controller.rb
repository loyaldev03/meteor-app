class OperationsController < ApplicationController
  before_filter :validate_club_presence
  before_filter :validate_member_presence

  def index
    if request.post?
      filter = params[:filter]
    end
    respond_to do |format|
      format.html
      format.json { render json: OperationsDatatable.new(view_context,@current_partner,@current_club,@current_member)}
    end
  end

  # GET /operations/1
  # GET /operations/1.json
  def show
    @operation = Operation.find(params[:id])
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @operation }
    end
  end

  # PUT /operations/1
  # PUT /operations/1.json
  def update
    operation = Operation.find(params[:id])
    @url_helpers = Rails.application.routes.url_helpers
    respond_to do |format|
      if operation.update_attributes(params[:operation])
        message = "Edited operation note <a href=\"/partner/#{@current_partner.prefix}/club/#{@current_club.name}/member/#{@current_member.visible_id}/operations/#{operation.id}\">#{operation.id}</a>.".html_safe
        operation.description = message
        operation.save
        Auditory.audit(@current_agent, operation, message, @current_member)
        format.html { redirect_to operation_path(:id => operation), notice: message }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: operation.errors, status: :unprocessable_entity }
      end
    end
  end

end
