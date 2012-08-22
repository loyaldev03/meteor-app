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
  def show
    @operation = Operation.find(params[:id])
  end

  # PUT /operations/1
  def update
    operation = Operation.find(params[:id])
    @url_helpers = Rails.application.routes.url_helpers
    if operation.update_attributes(params[:operation])
      message = "Edited operation note <a href=\"/partner/#{@current_partner.prefix}/club/#{@current_club.name}/member/#{@current_member.visible_id}/operations/#{operation.id}\">#{operation.id}</a>.".html_safe
      Auditory.audit(@current_agent, operation, message, @current_member)
      redirect_to operation_path(:id => operation), notice: message
    else
      render action: "edit" 
    end
  end

end
