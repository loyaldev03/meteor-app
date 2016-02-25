class DispositionTypesController < ApplicationController
  before_filter :validate_club_presence
  authorize_resource :disposition_type

  def index
    my_authorize! :list, DispositionType, @current_club.id
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: DispositionTypesDatatable.new(view_context,@current_partner,@current_club,nil,@current_agent) }
    end
  end

  def new 
    my_authorize! :new, DispositionType, @current_club.id
    @disposition_type = DispositionType.new
  end

  def create 
    @disposition_type = DispositionType.new disposition_type_params
    my_authorize! :create, DispositionType, @current_club.id
    @disposition_type.club = @current_club
    if @disposition_type.save
      redirect_to disposition_types_path, :notice => "Disposition type #{@disposition_type.name} was succesfuly created."
    else
      render action: "new"
    end
  end

  def edit
  	@disposition_type = DispositionType.find params[:id]
    my_authorize! :edit, DispositionType, @disposition_type.club_id
  end

  def update
  	@disposition_type = DispositionType.find params[:id]
    my_authorize! :update, DispositionType, @disposition_type.club_id
  	if @disposition_type.update_attributes disposition_type_params
  		redirect_to disposition_types_path, :notice => 'Disposition type succesfuly created.'
  	else
      render action: "edit" 
  	end
  end

  private
    def disposition_type_params
      params.require(:disposition_type).permit(:name)
    end
end