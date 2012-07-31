class Admin::AgentsController < ApplicationController
  load_and_authorize_resource

  # GET /agents
  # GET /agents.xml
  def index
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: AgentsDatatable.new(view_context)  }
    end
  end

  # GET /agents/1
  # GET /agents/1.xml
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @agent }
    end
  end

  # GET /agents/new
  # GET /agents/new.xml
  def new
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @agent }
    end
  end

  # GET /agents/1/edit
  def edit
  end

  # POST /agents
  # POST /agents.xml
  def create
    respond_to do |format|
      if @agent.save
        format.html { redirect_to([ :admin, @agent ], :notice => 'Agent was successfully created.') }
        format.xml  { render :xml => @agent, :status => :created, :location => @agent }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @agent.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /agents/1
  # PUT /agents/1.xml
  def update
    cleanup_for_update!(params[:agent])
    respond_to do |format|
      if @agent.update_attributes(params[:agent])
        format.html { redirect_to([ :admin, @agent ], :notice => 'Agent was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @agent.errors, :status => :unprocessable_entity }
      end
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
  # DELETE /agents/1.xml
  def destroy
    @agent.destroy

    respond_to do |format|
      format.html { redirect_to(admin_agents_url) }
      format.xml  { head :ok }
    end
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
end
