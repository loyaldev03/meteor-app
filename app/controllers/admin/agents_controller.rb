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
    @clubs = Club.all
    
    # cleanup_for_update!(params[:agent])
    # if params[:agent][:club_roles_attributes].present? and not params[:agent][:roles].blank?
      # flash.now[:error] = 'Cannot set both global and club roles at the same time'
      # render :action => "new"
    # elsif @agent.save
    if @agent.save
      params[:club_roles_attributes].each do |club_role|
        @agent.club_roles << ClubRole.new(club_role.last)
      end
      @agent.save
      redirect_to([ :admin, @agent ], :notice => 'Agent was successfully created.') 
    else
      flash.now[:error] = 
      render :action => "new"
    end
  end

  # PUT /agents/1
  def update
    @clubs = Club.all
    cleanup_for_update!(params[:agent])
    if params[:agent][:club_roles_attributes].present? and not params[:agent][:roles].blank?
      flash.now[:error] = 'Cannot set both global and club roles at the same time'
      render :action => "edit" 
    elsif @agent.update_attributes(params[:agent])
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
        # if hash[:club_roles_attributes].present?
          # hash[:club_roles_attributes].reject! { |k,v| !v[:_destroy] && (v[:role].blank? || v[:club_id].blank?) }
        # end        
        if hash[:roles].blank?
          hash[:roles] = []
        end
      end
    end

  

end
