class ClubsController < ApplicationController
  layout '2-cols'

  def test_api_connection
    club = Club.find(params[:club_id])
    my_authorize!(:test_api_connection, Club, club.id)
    club.test_connection_to_api!
    flash[:notice] = "Phoenix can connect to the remote API correctly."
  rescue
    flash[:error] = "There was an error while connecting to the remote API. " + $!.to_s
  ensure
    redirect_to club_path(id: club.id)
  end  

  # GET /clubs
  # GET /clubs.json
  def index
    my_authorize_action_within_clubs!(:list, Club, @current_partner.clubs.collect(&:id))
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: ClubsDatatable.new(view_context,@current_partner,nil,nil,@current_agent) }
    end
  end

  # GET /clubs/1
  def show
    my_authorize!(:show, Club, params[:id])
    @club = Club.find(params[:id])
    @drupal_domain = Domain.find(@club.drupal_domain_id) if @club.drupal_domain_id
    @payment_gateway_configuration = @club.payment_gateway_configurations.first
    flash[:error] = "Marketing client is not correctly configured" unless @club.marketing_tool_correctly_configured? 
  end

  # GET /clubs/new
  def new
    my_authorize!(:new, Club)
    @club = Club.new
  end

  # GET /clubs/1/edit
  def edit
    my_authorize!(:show, Club, params[:id])
    @club = Club.find(params[:id])
  end

  # POST /clubs
  def create
    my_authorize!(:create, Club)
    @club = Club.new params.require(:club).permit(:name, :description, :cs_phone_number, :theme, :logo, :require_external_attributes, :club_cash_enable, :family_memberships_allowed, :time_zone, :member_banner_url, :non_member_banner_url, :member_landing_url, :non_member_landing_url, :api_type, :api_username, :api_password, :marketing_tool_client, :payment_gateway_errors_email)
    prepare_marketing_tool_attributes(params[:marketing_tool_attributes], params[:club][:marketing_tool_client]) if params[:marketing_tool_attributes]
    @club.partner = @current_partner
    if @club.save
      redirect_to club_path(:id => @club), notice: "The club #{@club.name} was successfully created."
    else
      render action: "new" 
    end
  end

  # PUT /clubs/1
  def update
    my_authorize!(:show, Club, params[:id])
    @club = Club.find(params[:id])
    prepare_marketing_tool_attributes(params[:marketing_tool_attributes], params[:club][:marketing_tool_client])
    unless check_domain_belongs_to_partner(params[:drupal_domain_id])
      flash.now[:error] = "Agent can't assign domain. Domain not available."
      render action: "edit" 
    else
      if @club.update params.require(:club).permit(:name, :description, :cs_phone_number, :theme, :logo, :require_external_attributes, :club_cash_enable, :family_memberships_allowed, :time_zone, :member_banner_url, :non_member_banner_url, :member_landing_url, :non_member_landing_url, :drupal_domain_id, :api_type, :api_username, :api_password, :marketing_tool_client, :payment_gateway_errors_email)
        redirect_to club_path(:partner_prefix => @current_partner.prefix, :id => @club.id), notice: "The club #{@club.name} was successfully updated."
      else
        render action: "edit"
      end
    end
  end

  # DELETE /clubs/1
  def destroy
    my_authorize!(:show, Club)
    @club = Club.find(params[:id])
    if @club.destroy
      redirect_to clubs_url, notice: "Club #{@club.name} was successfully destroyed"
    else
      flash[:error] = "Club #{@club.name} was not destroyed."
      redirect_to clubs_url
    end 
  end

  def marketing_tool_attributes
    my_authorize!(:marketing_tool_attributes, Club, params[:id])
    @club = params[:id].blank? ? Club.new : Club.find(params[:id])
    case params[:client]
    when 'exact_target'
      render :partial => "exact_target_marketing_tool_attributes", :locals => { :club => @club }
    when 'mailchimp_mandrill'
      render :partial => "mailchimp_mandrill_marketing_tool_attributes", :locals => { :club => @club }
    else
      render inline: "Does not need configuration."
    end
  end

  def check_domain_belongs_to_partner(drupal_domain_id)
    valid = true
    unless drupal_domain_id.blank?
      domain = Domain.find(drupal_domain_id)
      if domain.partner_id == @current_partner.id
        unless @current_agent.has_global_role? and domain.club 
          clubs_id = @current_agent.clubs.where("partner_id = ? and club_roles.role = 'admin'", @current_partner.id).collect(&:id)
          valid = false unless clubs_id.include?(domain.club_id)
        end   
      else
        valid = false
      end
    end
    valid
  rescue ActiveRecord::RecordNotFound
    false
  end


  def get_fulfillment_codes
    club = Club.find(params[:club_id])
    query = params[:query]
    fulfillment_codes = club.campaigns.select(:fulfillment_code).distinct.where("fulfillment_code LIKE '%#{query}%'").pluck(:fulfillment_code)
    values = []
    code_id = 0
    fulfillment_codes.each do |code|
      values << { id: code_id.to_s, text: code }
      code_id += 1
    end
    render json: values
  end

  def get_subscription_plans
    club = Club.find(params[:club_id])
    query = params[:query]
    subscription_plans = club.terms_of_memberships.select(:id, :name).where("name LIKE '%#{query}%'")
    values = []
    subscription_plans.each do |plan|
      values << { id: plan.id.to_s, text: plan.name }
    end
    render json: values
  end

  private 
    def prepare_marketing_tool_attributes(marketing_tool_attributes, marketing_tool_client)
      unless marketing_tool_attributes.nil?
        if not @club.new_record? and marketing_tool_client == 'exact_target'
          if marketing_tool_attributes[:et_password].blank?
            marketing_tool_attributes.delete(:et_password)
            marketing_tool_attributes.merge!({:et_password => @club.marketing_tool_attributes["et_password"]}) if @club.marketing_tool_attributes
          end
        end
      end
      @club.marketing_tool_attributes = marketing_tool_attributes
    end
end