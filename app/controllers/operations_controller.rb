class OperationsController < ApplicationController
  before_filter :validate_club_presence
  before_filter :validate_member_presence
  layout '2-cols'

  def index
    if request.post?
      filter = params[:filter]
    end
    respond_to do |format|
      format.html
      format.json { render json: OperationsDatatable.new(view_context,@current_partner,@current_club,@current_member)}
    end
  end

  # GET /domains/1
  # GET /domains/1.json
  def show
    @operation = Operation.find(params[:id])
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @operation }
    end
  end

  # PUT /domains/1
  # PUT /domains/1.json
  def update
    operation = Operation.find(params[:id])

    respond_to do |format|
      if operation.update_attributes(params[:operation])
        message = "Edited note #{operation.id}."
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
