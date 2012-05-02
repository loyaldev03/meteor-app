class OperationsController < ApplicationController
  before_filter :validate_member_presence
  layout '2-cols'

  # GET /domains
  # GET /domains.json
  def index

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

  # GET /domains/new
  # GET /domains/new.json
  def new
  end

  # GET /domains/1/edit
  def edit
  end

  # POST /domains
  # POST /domains.json
  def create
  end

  # PUT /domains/1
  # PUT /domains/1.json
  def update
    @operation = Operation.find(params[:id])

    respond_to do |format|
      if @operation.update_attributes(params[:operation])
        format.html { redirect_to operation_path(:id => @operation), notice: "The operation was successfully updated." }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @operation.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /domains/1
  # DELETE /domains/1.json
  def destroy
  end
end
