class Admin::AgentsController < ApplicationController
  before_filter :load_clubs_related, only: [ :new, :edit ]

  # GET /agents
  def index
    my_authorize_action_within_clubs!(:list, Agent)
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: AgentsDatatable.new(view_context,nil,nil,nil,@current_agent)  }
    end
  end

  # GET /agents/1
  def show
    @agent = Agent.find(params[:id])
    my_authorize_action_within_clubs!(:show, Agent, @agent.clubs_related_id_list)
    if @current_agent.has_global_role?
      @club_roles = @agent.club_roles
    else
      @club_roles = @current_agent.id == @agent.id ? @current_agent.club_roles : @agent.club_roles.where("club_id in (?)", @current_agent.clubs_related_id_list("admin"))
    end
  end

  # GET /agents/new
  def new
    my_authorize_action_within_clubs!(:new, Agent)
    @agent = Agent.new
  end

  # GET /agents/1/edit
  def edit
    @agent = Agent.find(params[:id])
    my_authorize_action_within_clubs!(:edit, Agent, @agent.clubs_related_id_list)
    if @current_agent.has_global_role?
      @club_roles = @agent.club_roles
    else
      @club_roles = @current_agent.id == @agent.id ? @current_agent.club_roles : @agent.club_roles.where("club_id in (?)", @current_agent.clubs_related_id_list("admin"))
    end
    @agent.clubs.each{ |c| @clubs = @clubs - [c] }
  end

  # POST /agents
  def create
    tmp_agent = Agent.where(email: params[:agent][:email]).with_deleted.first
    if tmp_agent and tmp_agent.deleted?
      @club_roles = []
      @agent = tmp_agent
      @agent.roles = nil
      @agent.delete_club_roles(tmp_agent.club_roles)
      @agent.assign_attributes agent_params
      @agent.deleted_at = nil
    else
      @agent = Agent.new agent_params
    end

    if @current_agent.has_global_role?
      my_authorize_action_within_clubs!(:create, Agent)
    elsif params[:club_roles_attributes]
      club_roles_id = []
      params[:club_roles_attributes].each{|k,v| club_roles_id << v["club_id"] }
      my_authorize_action_within_clubs!(:create, Agent, club_roles_id)
    end

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
      rescue Exception
        Auditory.report_issue("Agent:Create", $!)
        flash.now[:error] = I18n.t('error_messages.airbrake_error_message')
        raise ActiveRecord::Rollback
      end
    end
    if success
      redirect_to([ :admin, @agent ], :notice => 'Agent was successfully created.')
    else
      # TODO: review if this order it's ok.
      load_clubs_related
      @agent.clubs.each{ |c| @clubs = @clubs - [c] }
      @agent.reload unless @agent.new_record? #hack for deleted users
      render :action => "new"
    end
  end

  # PUT /agents/1
  def update
    @agent = Agent.find(params[:id])
    my_authorize_action_within_clubs!(:update, Agent, @agent.clubs_related_id_list)
    @club_roles = @agent.club_roles.where("club_id in (?)", @current_agent.clubs_related_id_list("admin"))
    success = false
    ClubRole.transaction do
      begin
        cleanup_for_update! params[:agent]
        if agent_params[:roles].present? and params[:club_roles_attributes].present?
          flash.now[:error] = 'Cannot set both global and club roles at the same time'
        elsif @agent.update_attributes agent_params
          if params[:club_roles_attributes]
            @agent.set_club_roles(params[:club_roles_attributes])
          end
          success = true
        end
      rescue ActiveRecord::RecordInvalid => e
        logger.error e
        flash.now[:error] = 'Agent was not updated.'
      rescue Exception
        Auditory.report_issue("Agent:Update", $!)
        flash.now[:error] = I18n.t('error_messages.airbrake_error_message')
        raise ActiveRecord::Rollback
      end
    end
    if success
      redirect_to([ :admin, @agent ], :notice => 'Agent was successfully updated.')
    else
      load_clubs_related
      @agent.clubs.each{ |c| @clubs = @clubs - [c] }
      render :action => "edit"
    end
  end

  # DELETE /agents/1
  def destroy
    @agent = Agent.find(params[:id])
    my_authorize_action_within_clubs!(:destroy, Agent, @agent.clubs_related_id_list)
    @agent.destroy
    redirect_to(admin_agents_url, :notice => 'Agent was successfully deleted.')
  end

  def my_clubs
    my_authorize_action_within_clubs!(:list_my_clubs, Club)
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: MyClubsDatatable.new(view_context,nil,nil,nil,@current_agent) }
    end
  end

  def update_club_role
    club_role = ClubRole.find(params[:id])
    club_role.role = params[:role]
    my_authorize!(:update_club_role, Agent, club_role.club_id)
    if club_role.save
      answer = { code: "000", message: "Club Role for #{club_role.club.name} updated successfully." }
    else
      answer = { code: Settings.error_codes.wrong_data, message: "Role could not be updated." }
    end
    render json: answer
  end

  def delete_club_role
    club_role = ClubRole.find(params[:id])
    my_authorize!(:update_club_role, Agent, club_role.club_id)
    if @current_agent.can_agent_by_role_delete_club_role(club_role)
      answer = { code: Settings.error_codes.wrong_data, message: "Role could not be deleted. It is the last one." }
    elsif club_role.destroy
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

    def load_clubs_related
      @clubs = @current_agent.has_global_role? ? Club.order("name ASC").select("id,name") : @current_agent.clubs.where("club_roles.role = 'admin'")
    end

    def agent_params
      params.require(:agent).permit(:email, :username, :password, :password_confirmation, :roles)
    end
end
