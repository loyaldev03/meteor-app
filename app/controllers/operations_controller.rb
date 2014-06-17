class OperationsController < ApplicationController
  before_filter :validate_club_presence
  before_filter :validate_member_presence

  def index
    my_authorize! :list, Operation, @current_club.id
    if request.post?
      filter = params[:filter]
    end
    respond_to do |format|
      format.html
      format.json { render json: OperationsDatatable.new(view_context, @current_partner, @current_club, @current_member, @current_agent)}
    end
  end

  # GET /operations/1
  def show
    @operation = Operation.find(params[:id])
    @member = Member.find(@operation.member_id)
    my_authorize! :edit, Operation, @member.club_id
  end

  # PUT /operations/1
  def update
    operation = Operation.find(params[:id])
    @member = Member.find(operation.member_id)
    my_authorize! :edit, Operation, @member.club_id
    @link = (view_context.link_to "#{operation.id}", operation_path(@current_partner.prefix,@current_club.name,@current_member.id,operation.id))
    if operation.update_attributes(params[:operation])
      message = "Edited operation note #{@link}".html_safe
      Auditory.audit(@current_agent, operation, message, @current_member, Settings.operation_types.operation_updated)
      redirect_to operation_path(:id => operation), notice: message
    else
      render action: "show" 
    end
  end

end
