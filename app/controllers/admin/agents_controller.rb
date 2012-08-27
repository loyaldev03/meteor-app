class Admin::AgentsController < ApplicationController
  load_and_authorize_resource
  skip_authorize_resource :only => :my_clubs

  # GET /agents
  def index
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: AgentsDatatable.new(view_context)  }
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
  end

  # POST /agents
  def create
    @clubs = Club.all
    if @agent.save
      redirect_to([ :admin, @agent ], :notice => 'Agent was successfully created.') 
    else
      render :action => "new" 
    end
  end

  # PUT /agents/1
  def update
    @clubs = Club.all
    cleanup_for_update!(params[:agent])
    if @agent.update_attributes(params[:agent])
      redirect_to([ :admin, @agent ], :notice => 'Agent was successfully updated.') 
    else
      render :action => "edit" 
    end
  end

  def cleanup_for_update!(hash)
    if hash
      if hash[:password].blank?
        hash.delete(:password)
        hash.delete(:password_confirmation)
      end
      if hash[:club_roles_attributes].present?
        hash[:club_roles_attributes].reject! { |k,v| !v[:_destroy] && (v[:role].blank? || v[:club_id].blank?) }
      end
    end
  end

  # DELETE /agents/1
  def destroy
    @agent.destroy
    redirect_to(admin_agents_url, :notice => 'Agent was successfully deleted.')
  end

  def lock
    agent = Agent.find(params[:agent_id])
    authorize! :write, agent
    agent.lock_access!
    redirect_to(admin_agents_path, :notice => "Agent number #{agent.id} - #{agent.username} - was locked.")
  end

  def unlock
    agent = Agent.find(params[:agent_id])
    authorize! :write, agent
    agent.unlock_access!
    redirect_to(admin_agents_path, :notice => "Agent number #{agent.id} - #{agent.username} - was unlocked.")
  end

  def my_clubs
    if current_agent.has_role? 'admin'
      @clubs = Club.all
    else
      @my_roles = @current_agent.club_roles
    end
  end

end
