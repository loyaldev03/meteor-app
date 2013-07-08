class DispositionTypesController < ApplicationController
  before_filter :validate_club_presence
  authorize_resource :disposition_type

  def index
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: DispositionTypesDatatable.new(view_context,@current_partner,@current_club,nil,@current_agent) }
    end
  end

  def new 
    @disposition_type = DispositionType.new
  end

  def create 
    @disposition_type = DispositionType.new params[:disposition_type]
    @disposition_type.club = @current_club
    if @disposition_type.save
      redirect_to disposition_types_path, :notice => "Disposition type #{@disposition_type.name} was succesfuly created."
    else
      render action: "new"
    end
  end

  def edit
  	@disposition_type = DispositionType.find params[:id]
  end

  def update
  	@disposition_type = DispositionType.find params[:id]
  	if @disposition_type.update_attributes params[:disposition_type]
  		redirect_to disposition_types_path, :notice => 'Disposition type succesfuly created.'
  	else
      render action: "edit" 
  	end
  end

  def destroy
    @disposition_type = DispositionType.find params[:id]
    if @disposition_type.delete
      redirect_to disposition_types_path, :notice => "Disposition type #{@disposition_type.name} was succesfuly deleted."
    else 
      redirect_to disposition_types_path(:id => @disposition_type), :flash => { error: "The disposition type #{@disposition_type.name} could not be destroyed."}
    end
  end

end