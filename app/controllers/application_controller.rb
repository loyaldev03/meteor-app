class ApplicationController < ActionController::Base
  before_filter :authenticate_agent!
  before_filter :validate_partner_presence
  protect_from_forgery

  def after_sign_in_path_for(resource)
    return session[:agent_return_to] if session[:agent_return_to]
    sign_in_url = url_for(:action => 'new', :controller => 'sessions', :only_path => false, :protocol => 'http')    
    if @current_agent and @current_agent.has_role? 'admin'
      return admin_partners_path
    end
    root_path
  end

  rescue_from CanCan::AccessDenied do |exception|
    render :file => "#{Rails.root}/public/401", :status => 401, :layout => false, :formats => [:html]
  end

  private

    def my_authorize!(action, what, club_id = nil)
      raise CanCan::AccessDenied unless current_agent.can?(action, what, club_id)
    end

    #TODO: Merge this method with 'my_authorize'
    #Used to check if the agent is allowed to make any of these actions within a given list of clubs or it's own.
    def my_authorize_action_within_clubs!(action, model, club_id_list=nil)
      allowed = @current_agent.can? action, model
      unless allowed
        club_id_list ||= @current_agent.clubs_related_id_list
        club_id_list.each do |club_id|
          allowed = true if @current_agent.can? action, model, club_id
        end
      end
      raise CanCan::AccessDenied unless allowed
    end

    def current_ability
      Ability.new(current_agent, params[:club_id] || (@current_club.id rescue nil))
    end

    def validate_partner_presence
      if current_agent
        if params[:partner_prefix].nil? and 
                not params[:controller].include?('api/') and 
                not params[:controller].include?('admin/') and 
                not params[:controller].include?('devise/')
          flash[:error] = "No partner was selected."
          redirect_to admin_partners_path
          false
        elsif not params[:partner_prefix].nil?
          @current_partner = Partner.find_by_prefix(params[:partner_prefix])
          if @current_partner.nil?
            flash[:error] = "No partner was selected."
            redirect_to admin_partners_path
            false
          end
        end
      end
    end

    def validate_club_presence
      if current_agent
        if params[:club_prefix].nil?
          flash[:error] = "No club was selected."
          redirect_to clubs_path
          false
        else
          @current_club = @current_partner.clubs.find_by_name(params[:club_prefix])
          if @current_club.nil?
            flash[:error] = "No club was selected."
            redirect_to clubs_path
            false
          else
            Time.zone = @current_club.time_zone
            flash.now[:error] = "This club is currenlty disabled." unless @current_club.billing_enable
          end
        end
      end
    end

    def validate_user_presence
      if current_agent 
        if params[:user_prefix].nil?
          flash[:error] = "No user was selected."
          redirect_to clubs_path
          false
        else
          @current_user = User.find_by_id_and_club_id(params[:user_prefix], @current_club.id)
          if @current_user.nil?
            flash[:error] = "No user was selected."
            redirect_to clubs_path
            false
          end
        end
      end
    end
end
