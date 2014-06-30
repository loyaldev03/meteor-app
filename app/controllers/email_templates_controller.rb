class EmailTemplatesController < ApplicationController

	before_filter :validate_partner_presence
	before_filter :validate_club_presence
	
	def index
		my_authorize! :list, EmailTemplate, @current_club.id
		@tom = TermsOfMembership.find(params[:terms_of_membership_id])
		if @tom
			respond_to do |format|
				format.html # index.html.erb
				format.json { render json: EmailTemplatesDatatable.new(view_context, @current_partner, @current_club, nil, @current_agent) }
			end
		else
			redirect_to terms_of_memberships_url, :error => "Subscription Plan not found."
		end
	end

	def new
		my_authorize! :new, EmailTemplate, @current_club.id
		@et = EmailTemplate.new
		@tom = TermsOfMembership.find(params[:terms_of_membership_id])
		if @tom			
			@et.terms_of_membership_id = @tom.id
		else
			redirect_to terms_of_memberships_url, :error => "Subscription Plan not found."
		end
	end

	def create
		my_authorize! :create, EmailTemplate, @current_club.id
		@et = EmailTemplate.new(params[:tom])
		@tom = TermsOfMembership.find(params[:terms_of_membership_id])
		if @tom
			prepare_et_data_to_save(params)
			if @et.save
				redirect_to terms_of_membership_email_templates_url, :notice => "Your Communication #{@et.name} (ID: #{@et.id}) was successfully created"
			else
				flash.now[:error] = "There was an error while trying to save this Communication."
				render action: "new"
			end
		else
			redirect_to terms_of_memberships_url, :error => "Subscription Plan not found."
		end
	end

	def edit  
		@et = EmailTemplate.find(params[:id])
		@tom = TermsOfMembership.find(@et.terms_of_membership_id)
		my_authorize! :edit, EmailTemplate, @tom.club_id
		if !@et.external_attributes
			attributes = Hash.new()
			@et.external_attributes = attributes
		end
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
				flash[:notice] = "Your Communication #{@et.name} (ID: #{@et.id}) was succesfully updated"
				redirect_to terms_of_membership_email_templates_url
			else
				flash[:error] = "Your Communication was not updated."
				render action: "edit"
			end
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

	def external_attributes_html()
		render :partial => "external_attributes_html.html.erb", :locals => { :client => params[:client], :ea => params[:ea] }
	end

	private
	def prepare_et_data_to_save(post_data)
		@et.name = post_data[:email_template][:name]
		@et.terms_of_membership_id = @tom.id
		@et.template_type = post_data[:template_type]
		if @et.template_type == 'pillar'
			@et.days_after_join_date = post_data[:email_template][:days_after_join_date].to_i
		else
			@et.days_after_join_date = nil
		end
		@et.client = post_data[:client]
		attributes = Hash.new()
		ea_keys = external_attributes(@et.client)
		ea_keys.each do |attrib|
			attributes[attrib.to_sym] = post_data[attrib]
		end
		@et.external_attributes = attributes
	end

	def external_attributes(client)
		case client
			when "action_mailer"
				['trigger_id', 'mlid', 'site_id']
			when 'exact_target'
				['trigger_id', 'mlid', 'site_id', 'customer_key']
			when 'lyris'
				['trigger_id', 'mlid', 'site_id']
			else
				[]
		end
	end
end
