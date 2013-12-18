class Admin::AgentsController < ApplicationController
  load_and_authorize_resource :agent, :except => :my_clubs

  # GET /agents
  def index
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: AgentsDatatable.new(view_context,nil,nil,nil,@current_agent)  }
    end
  end

  # GET /agents/1
  def show
  end

  # GET /agents/new
  def new
    @clubs = Club.all
  end

  # GET /agents/1/edit
  def edit
    @clubs = Club.all
    @agent.clubs.each {|c| @clubs.delete(c)}
  end


  # POST /agents
  def create
    success = false
    @clubs = Club.all
    ClubRole.transaction do
      begin
        if params[:agent][:roles].present? and params[:club_roles_attributes].present?
          flash.now[:error] = 'Cannot set both global and club roles at the same time'
        else
          @agent.save!
          if params[:club_roles_attributes]
            @agent.set_club_roles(params[:club_roles_attributes])
          end
          success = true
        end
      rescue ActiveRecord::RecordInvalid
        @agent.errors.add(:email, "has already been taken")
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
    success = false
    @clubs = Club.where(["id not in (?)", @agent.club_roles.each.collect(&:club_id)])
    ClubRole.transaction do
      begin
        cleanup_for_update!(params[:agent])
        if params[:agent][:roles].present? and params[:club_roles_attributes].present?
          flash.now[:error] = 'Cannot set both global and club roles at the same time'
        elsif @agent.update_attributes(params[:agent])
          if params[:club_roles].present?
            @agent.delete_club_roles(params[:club_roles][:delete])
          end
          if params[:club_roles_attributes]
            @agent.set_club_roles(params[:club_roles_attributes])
          end
          success = true
        end
      rescue ActiveRecord::RecordNotUnique
        @agent.errors.add(:email, "has already been taken")
        success = false
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
    @agent.destroy
    redirect_to(admin_agents_url, :notice => 'Agent was successfully deleted.')
  end

  def my_clubs
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: MyClubsDatatable.new(view_context,nil,nil,nil,@current_agent) }
    end
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

  

end
