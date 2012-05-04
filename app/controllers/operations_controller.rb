class OperationsController < ApplicationController
  before_filter :validate_club_presence
  before_filter :validate_member_presence
  layout '2-cols'

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
        message = "Edited operation (#{operation.operation_date}) notes."
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
