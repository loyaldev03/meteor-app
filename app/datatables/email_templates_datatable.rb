class EmailTemplatesDatatable < Datatable
private
  def data
    email_templates.map do |email_template|
      [
        email_template.id,
        email_template.name, 
        email_template.template_type,
        email_template.client.humanize,
        (link_to(I18n.t(:show), 
        	@url_helpers.terms_of_membership_email_template_path(
        		:partner_prefix => @current_partner.prefix, 
        		:club_prefix => @current_club.name, 
        		:terms_of_membership_id => TermsOfMembership.find(email_template.terms_of_membership_id).id, 
        		:id => email_template.id
        	), 
        	:class => 'btn btn-mini') if @current_agent.can? :show, EmailTemplate, @current_club.id
      	) +
      	(link_to(I18n.t(:edit), 
        	@url_helpers.edit_terms_of_membership_email_template_path(
        		:partner_prefix => @current_partner.prefix, 
        		:club_prefix => @current_club.name, 
        		:terms_of_membership_id => TermsOfMembership.find(email_template.terms_of_membership_id).id, 
        		:id => email_template.id
        	), 
        	:class => 'btn btn-mini') if @current_agent.can? :edit, EmailTemplate, @current_club.id
      	) +
      	(link_to(I18n.t(:destroy), 
        	@url_helpers.terms_of_membership_email_template_path(
        		:partner_prefix => @current_partner.prefix, 
        		:club_prefix => @current_club.name, 
        		:terms_of_membership_id => TermsOfMembership.find(email_template.terms_of_membership_id).id, 
        		:id => email_template.id
        	), 
        	:method => :delete, data: {:confirm => I18n.t("are_you_sure")}, :id => 'destroy', :class => 'btn btn-mini btn-danger') if @current_agent.can? :destroy, EmailTemplate, @current_club.id
      	)
      ]
    end
  end

	def email_templates
		@email_templates ||= fetch_email_templates
	end

	def fetch_email_templates
    tom = TermsOfMembership.find(params[:terms_of_membership_id])
		email_templates = EmailTemplate.where(:terms_of_membership_id => tom.id, :client => tom.club.marketing_tool_client)
		email_templates = email_templates.page(page).per_page(per_page)
		if params[:sSearch].present?
			email_templates = email_templates.where("id LIKE :search OR name LIKE :search OR template_type LIKE :search", search: "%#{params[:sSearch]}%")
		end
		email_templates
	end

  def total_records
    TermsOfMembership.find(params[:terms_of_membership_id]).email_templates.count
  end

  def total_entries
    email_templates.count
  end

  def sort_column
    EmailTemplate.datatable_columns[params[:iSortCol_0].to_i]
  end
end
