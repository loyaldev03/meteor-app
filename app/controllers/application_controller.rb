class ApplicationController < ActionController::Base
  before_filter :authenticate_agent!
  before_filter :validate_partner_presence
  protect_from_forgery

  def after_sign_in_path_for(resource)
    sign_in_url = url_for(:action => 'new', :controller => 'sessions', :only_path => false, :protocol => 'http')    
    if @current_agent
      if @current_agent.has_role? 'admin'
        admin_partners_path
      else
        admin_agent_my_clubs_path(@current_agent.id)
      end
    else
      new_agent_session_path
    end
  end

  rescue_from CanCan::AccessDenied do |exception|
    render :file => "#{Rails.root}/public/401.html", :status => 401, :layout => false
  end

  private

    def current_ability
      @current_ability ||= Ability.new(current_agent)
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
          @current_club = Club.find_by_name(params[:club_prefix])
          if @current_club.nil?
            flash[:error] = "No club was selected."
            redirect_to clubs_path
            false
          else
            Time.zone = @current_club.time_zone
          end
        end
      end
    end

    def validate_member_presence
      if current_agent 
        if params[:member_prefix].nil?
          flash[:error] = "No member was selected."
          redirect_to clubs_path
          false
        else
          @current_member = Member.find_by_visible_id_and_club_id(params[:member_prefix], @current_club.id)
          if @current_member.nil?
            flash[:error] = "No member was selected."
            redirect_to clubs_path
            false
          end
        end
      end
    end
end
