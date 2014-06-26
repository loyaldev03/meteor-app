class EmailTemplatesController < ApplicationController

	before_filter :validate_partner_presence
	before_filter :validate_club_presence
	
	def index
		my_authorize! :create, EmailTemplate, @current_club.id
		@tom = TermsOfMembership.find(params[:terms_of_membership_id])
		respond_to do |format|
      format.html # index.html.erb
      format.json { render json: EmailTemplatesDatatable.new(view_context, @current_partner, @current_club, nil, @current_agent) }
    end
	end

	def new
    my_authorize! :new, EmailTemplate, @current_club.id
		@et = EmailTemplate.new
		@tom = TermsOfMembership.find(params[:terms_of_membership_id])
		@et.terms_of_membership_id = @tom.id
	end

  def create
  	my_authorize! :create, EmailTemplate, @current_club.id
    @et = EmailTemplate.new(params[:email_template])
    @tom = TermsOfMembership.find(params[:terms_of_membership_id])
    prepare_et_data_to_save(params)
    if @et.save
      redirect_to terms_of_membership_email_templates_url, :notice => "Your Communication #{@et.name} (ID: #{@et.id}) was successfully created"
    else
      flash.now[:error] = "There was an error while trying to save this Communication."
      render action: "new"
    end
  end

	def edit  
		@et = EmailTemplate.find(params[:id])
		@tom = TermsOfMembership.find(@et.terms_of_membership_id)
    my_authorize! :edit, EmailTemplate, @tom.club_id
	end

	def update
	@et = EmailTemplate.find(params[:id])
	@tom = TermsOfMembership.find(@et.terms_of_membership_id)
  my_authorize! :update, EmailTemplate, @tom.club_id
  prepare_et_data_to_save(params)
  if @et.save
    flash[:notice] = "Your Communication #{@et.name} (ID: #{@et.id}) was succesfully updated"
    redirect_to terms_of_membership_email_templates_url
  else
    flash.now[:error] = "Your Communication was not updated."
    render action: "edit"
  end
	end

	def show
		@et = EmailTemplate.find(params[:id])
		@tom = TermsOfMembership.find(@et.terms_of_membership_id)
		my_authorize! :show, EmailTemplate, @tom.club_id
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
    redirect_to terms_of_membership_email_templates_url
	end

	private
	def prepare_et_data_to_save(post_data)
		@et.terms_of_membership_id = @tom.id
		@et.template_type = post_data[:template_type]
		if @et.template_type == 'pillar'
			@et.days_after_join_date = post_data[:email_template][:days_after_join_date].to_i
		else
			@et.days_after_join_date = nil
		end
		@et.client = post_data[:client]		
		@et.external_attributes = post_data[:email_template][:external_attributes].sub(/\s+\Z/, '') == '' ? nil : post_data[:email_template][:external_attributes].sub(/\s+\Z/, '')
	end

end
