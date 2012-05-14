class Admin::AgentsController < ApplicationController
  # GET /agents
  # GET /agents.xml
  def index
    #@agents = Agent.paginate :page => params[:page] we dont use this, cause we are using datatable.
    @agents = Agent.all
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @agents }
    end
  end

  # GET /agents/1
  # GET /agents/1.xml
  def show
    @agent = Agent.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @agent }
    end
  end

  # GET /agents/new
  # GET /agents/new.xml
  def new
    @agent = Agent.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @agent }
    end
  end

  # GET /agents/1/edit
  def edit
    @agent = Agent.find(params[:id])
  end

  # POST /agents
  # POST /agents.xml
  def create
    @agent = Agent.new(params[:agent])

    respond_to do |format|
      if @agent.save
        @agent.confirm!
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
    @agent = Agent.find(params[:id])

    respond_to do |format|
      if @agent.update_attributes(params[:agent])
        @agent.confirm!
        format.html { redirect_to([ :admin, @agent ], :notice => 'Agent was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @agent.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /agents/1
  # DELETE /agents/1.xml
  def destroy
    @agent = Agent.find(params[:id])
    @agent.destroy

    respond_to do |format|
      format.html { redirect_to(admin_agents_url) }
      format.xml  { head :ok }
    end
  end

  def lock
    agent = Agent.find(params[:agent_id])
    agent.lock_access!
    redirect_to(admin_agents_path, :notice => "Agent number #{agent.id} - #{agent.username} - was locked.")
  end

  def unlock
    agent = Agent.find(params[:agent_id])
    agent.unlock_access!
    redirect_to(admin_agents_path, :notice => "Agent number #{agent.id} - #{agent.username} - was unlocked.")
  end
end
