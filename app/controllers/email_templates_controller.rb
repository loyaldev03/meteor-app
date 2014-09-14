class EmailTemplatesController < ApplicationController

  before_filter :validate_partner_presence
  before_filter :validate_club_presence
  
  def index
    @tom = TermsOfMembership.find(params[:terms_of_membership_id])
    my_authorize! :list, EmailTemplate, @tom.club_id
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: EmailTemplatesDatatable.new(view_context, @current_partner, @current_club, nil, @current_agent) }
    end
  rescue ActiveRecord::RecordNotFound 
    flash[:error] = "Subscription Plan not found."
    redirect_to terms_of_memberships_url 
  end

  def new
    @tom = TermsOfMembership.find(params[:terms_of_membership_id])
    my_authorize! :new, EmailTemplate, @tom.club_id
    unless @tom.club.marketing_tool_client.blank?
      @et = EmailTemplate.new client: @tom.club.marketing_tool_client
    else
      flash[:error] = "Configure a marketing tool client before creating communication templates."
      redirect_to club_path(id: @current_club.id)
    end
  rescue ActiveRecord::RecordNotFound 
    flash[:error] = "Subscription Plan not found."
    redirect_to terms_of_memberships_url 
  end

  def create
    @tom = TermsOfMembership.find(params[:terms_of_membership_id])
    my_authorize! :create, EmailTemplate, @tom.club_id

    @et = EmailTemplate.new(params[:email_template])
    @et.client = @tom.club.marketing_tool_client
    @et.terms_of_membership_id = @tom.id
    prepare_et_data_to_save(params)
    
    if @et.save
      redirect_to terms_of_membership_email_templates_url, :notice => "Your Communication #{@et.name} (ID: #{@et.id}) was successfully created"
    else
      flash.now[:error] = "There was an error while trying to save this Communication."
      render action: "new"
    end
  rescue ActiveRecord::RecordNotFound 
    flash[:error] = "Terms of membership not found."
    redirect_to terms_of_membership_email_templates_path
  end

  def edit  
    @et = EmailTemplate.find(params[:id])
    @tom = TermsOfMembership.find(@et.terms_of_membership_id)
    my_authorize! :edit, EmailTemplate, @tom.club_id
    if !@et.external_attributes
      attributes = Hash.new()
      @et.external_attributes = attributes
    end
  rescue ActiveRecord::RecordNotFound 
    flash[:error] = "Email Template not found."
    redirect_to terms_of_membership_email_templates_path
  end

  def update
    @et = EmailTemplate.find(params[:id])
    @tom = TermsOfMembership.find(@et.terms_of_membership_id)
    my_authorize! :update, EmailTemplate, @tom.club_id
    template_type = params[:template_type]
    templates_used = TermsOfMembership.find(@tom.id).email_templates.collect(&:template_type)
    if template_type != 'pillar' && templates_used.include?(template_type) && @et.template_type != template_type
      flash[:error] = "Template Type already in use."
      render action: "edit"
    else
      prepare_et_data_to_save(params)
      if @et.save
        flash[:notice] = "Your Communication #{@et.name} (ID: #{@et.id}) was successfully updated"
        redirect_to terms_of_membership_email_templates_url
      else
        flash[:error] = "Your Communication was not updated."
        render action: "edit"
      end
    end
  rescue ActiveRecord::RecordNotFound 
    flash[:error] = "Terms of membership or email template not found."
    redirect_to terms_of_memberships_url
  end

  def show
    @et = EmailTemplate.find(params[:id])
    @tom = TermsOfMembership.find(@et.terms_of_membership_id)
    my_authorize! :show, EmailTemplate, @tom.club_id
  rescue ActiveRecord::RecordNotFound 
    flash[:error] = "Email Template not found."
    redirect_to terms_of_memberships_url
  end

  def destroy
    @et = EmailTemplate.find(params[:id])
    @tom = TermsOfMembership.find(@et.terms_of_membership_id)
    my_authorize! :destroy, EmailTemplate, @tom.club_id
    if @et.destroy
      flash[:notice] = "Communication #{@et.name} (ID: #{@et.id}) was successfully destroyed."
    else
      flash[:error] = "Communication #{@et.name} (ID: #{@et.id}) was not destroyed."
    end
    redirect_to terms_of_membership_email_templates_path
  rescue ActiveRecord::RecordNotFound 
    flash[:error] = "Email Template not found."
    redirect_to terms_of_membership_email_templates_path
  end

  def test_communications
    if request.post? 
      begin
        template = EmailTemplate.find_by_id (params[:email_template_id]) 
        if template.nil?
          response = { code: Settings.error_codes.not_found, message: "Template not found."}
        else
	        my_authorize! :test_communications, EmailTemplate, template.terms_of_membership.club_id
	        user = User.find_by_id params[:user_id]
	        response = if user.nil?
	          { code: Settings.error_codes.not_found, message: "Member not found."}
	        elsif user.club_id != template.terms_of_membership.club_id
	          { code: Settings.error_codes.wrong_data, message: "Member does not belong to same club as the Template."}
	        elsif params[:terms_of_membership_id].to_i != template.terms_of_membership_id
	          { code: Settings.error_codes.wrong_data, message: "Terms of membership does not belong to this Subscription Plan." }
	        else
	          Communication.test_deliver!(template, user)
	        end
        end
        render json: response
      rescue CanCan::AccessDenied => e
        raise e
      rescue Exception => e
        Auditory.report_issue("EmailTemplate::test_communication", e, { :user => user.inspect, :template => template.inspect })
        render json: { code: Settings.error_codes.unrecoverable_error, message: e.to_s}
      end
    else
      @tom = TermsOfMembership.find(params[:terms_of_membership_id])
      my_authorize! :test_communications, EmailTemplate, @tom.club_id
      @email_templates = EmailTemplate.where(:terms_of_membership_id => @tom.id, :client => @tom.club.marketing_tool_client)
      @et = EmailTemplate.new
    end
  end

  def external_attributes
    render :partial => "external_attributes.html.erb", :locals => { :client => params[:client], :ea => params[:ea] }
  end

  private
    def prepare_et_data_to_save(post_data)
      @et.name = post_data[:email_template][:name]
      @et.template_type = post_data[:email_template][:template_type]
      if @et.template_type == 'pillar'
        @et.days_after_join_date = post_data[:email_template][:days_after_join_date].to_i
      else
        @et.days_after_join_date = nil
      end
      attributes = Hash.new()
      ea_keys = EmailTemplate.external_attributes_related_to_client(@et.client)
      ea_keys.each do |attrib|
        attributes[attrib.to_sym] = post_data[attrib]
      end
      @et.external_attributes = attributes
    end
end
