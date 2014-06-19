class Admin::AgentsController < ApplicationController
  before_filter :load_clubs_related, only: [ :new, :edit, :create, :update ]

  # GET /agents
  def index
    my_authorize_agents!(:list, Agent)
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: AgentsDatatable.new(view_context,nil,nil,nil,@current_agent)  }
    end
  end

  # GET /agents/1
  def show
    @agent = Agent.find(params[:id])
    if @current_agent.has_global_role?
      @club_roles = @agent.club_roles
    else
      @club_roles = @current_agent.id == @agent.id ? @current_agent.club_roles : @agent.club_roles.where("club_id in (?)", @current_agent.club_roles.where("role = 'admin'").collect(&:club_id))
    end
    my_authorize_agents!(:show, Agent, @agent.clubs.each.collect(&:id))
  end 

  # GET /agents/new
  def new
    my_authorize_agents!(:new, Agent)
    @agent = Agent.new
  end

  # GET /agents/1/edit
  def edit
    @agent = Agent.find(params[:id])
    if @current_agent.has_global_role?
      @club_roles = @agent.club_roles
    else
      @club_roles = @current_agent.id == @agent.id ? @current_agent.club_roles : @agent.club_roles.where("club_id in (?)", @current_agent.club_roles.where("role = 'admin'").collect(&:club_id))
    end
    my_authorize_agents!(:edit, Agent, @agent.clubs.collect(&:id))
    @agent.clubs.each{ |c| @clubs = @clubs - [c] }
  end

  # POST /agents
  def create
    my_authorize_agents!(:create, Agent)
    @agent = Agent.new(params[:agent])
    @agent.clubs.each{ |c| @clubs = @clubs - [c] }
    success = false
    ClubRole.transaction do
      begin
        if params[:agent][:roles].present? and params[:club_roles_attributes].present?
          flash.now[:error] = 'Cannot set both global and club roles at the same time'
        elsif not @current_agent.has_global_role? and not params[:club_roles_attributes].present?
          flash.now[:error] = 'Cannot create agent without roles.'
        else
          @agent.save!
          if params[:club_roles_attributes]
            @agent.set_club_roles(params[:club_roles_attributes])
          end
          success = true
        end
      rescue ActiveRecord::RecordInvalid => e
        logger.error e
        flash.now[:error] = 'Agent was not saved.'
      rescue Exception => e        
        Auditory.report_issue("Agent:Create", e, { :agent => @agent.inspect, :club_roles_attributes => params[:club_roles_attributes] })
        flash.now[:error] = I18n.t('error_messages.airbrake_error_message')
        raise ActiveRecord::Rollback
      end
    end
    if success 
      redirect_to([ :admin, @agent ], :notice => 'Agent was successfully created.') 
    else
      render :action => "new"
    end
  end

  # PUT /agents/1
  def update
    @agent = Agent.find(params[:id])
    my_authorize_agents!(:update, Agent, @agent.clubs.collect(&:id))
    @agent.clubs.each{ |c| @clubs = @clubs - [c] }
    @club_roles = @agent.club_roles.where("club_id in (?)", @current_agent.club_roles.where("role = 'admin'").collect(&:club_id))
    success = false
    ClubRole.transaction do
      begin
        cleanup_for_update!(params[:agent])
        if params[:agent][:roles].present? and params[:club_roles_attributes].present?
          flash.now[:error] = 'Cannot set both global and club roles at the same time'
        elsif @agent.update_attributes(params[:agent])
          if params[:club_roles_attributes]
            @agent.set_club_roles(params[:club_roles_attributes])
          end
          success = true
        end
      rescue ActiveRecord::RecordInvalid => e
        logger.error e
        flash.now[:error] = 'Agent was not updated.'
      rescue Exception => e
        Auditory.report_issue("Agent:Update", e, { :agent => @agent.inspect, :club_roles_attributes => params[:club_roles_attributes] })
        flash.now[:error] = I18n.t('error_messages.airbrake_error_message')
        raise ActiveRecord::Rollback
      end
    end
    if success 
      redirect_to([ :admin, @agent ], :notice => 'Agent was successfully updated.') 
    else
      render :action => "edit"
    end
  end

  # DELETE /agents/1
  def destroy
    @agent = Agent.find(params[:id])
    my_authorize_agents!(:destroy, Agent, @agent.clubs.collect(&:id))
    @agent.destroy
    redirect_to(admin_agents_url, :notice => 'Agent was successfully deleted.')
  end

  def my_clubs
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: MyClubsDatatable.new(view_context,nil,nil,nil,@current_agent) }
    end
  end

  def update_club_role
    club_role = ClubRole.find(params[:id])
    club_role.role = params[:role]
    if club_role.save
      answer = { code: "000", message: "Club Role for #{club_role.club.name} updated successfully." }
    else
      answer = { code: Settings.error_codes.wrong_data, message: "Role could not be updated." }
    end
    render json: answer
  end

  def delete_club_role
    club_role = ClubRole.find(params[:id])
    if @current_agent.can_agent_by_role_delete_club_role(club_role)
      answer = { code: Settings.error_codes.wrong_data, message: "Role could not be deleted. It is the last one." }
    elsif club_role.delete
      answer = { code: "000", message: "Club Role deleted successfully" }
    else
      answer = { code: Settings.error_codes.wrong_data, message: "Role could not be deleted." }
    end
    render json: answer
  end

  private

    def cleanup_for_update!(hash)
      if hash
        if hash[:password].blank?
          hash.delete(:password)
          hash.delete(:password_confirmation)
        end
        if hash[:roles].blank?
          hash[:roles] = ""
        end
      end
    end

    def my_authorize_agents!(action, model, club_id_list=nil)
      raise CanCan::AccessDenied unless @current_agent.has_role_or_has_club_role_where_can?(action, model, club_id_list)
    end

    def load_clubs_related
      @clubs = @current_agent.has_global_role? ? Club.all : @current_agent.clubs.where("club_roles.role = 'admin'")
    end
end
