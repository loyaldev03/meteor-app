class ApplicationController < ActionController::Base
  before_filter :authenticate_user!
  before_filter :validate_partner_presence
  protect_from_forgery

  private

    def validate_partner_presence
      if current_user 
        if params[:partner_prefix].nil? and not params[:controller].include?('admin/') and not params[:controller].include?('devise/')
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
      if current_user 
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
          end
        end
      end
    end
end
