module EmailTemplatesHelper
	def clients_options
	clients = [ ['Exact Target', 'exact_target'] ]
	clients << ['Action Mailer', 'action_mailer'] unless Rails.env.production?
	clients
	end
	
	def template_types_options(tom_id, current_type)
               templates_used = TermsOfMembership.find(tom_id).email_templates.where(client: client).pluck(&:template_type)
		result = []
		free_templates = EmailTemplate::TEMPLATE_TYPES.collect{|template| template.to_s } - templates_used + Array(current_type)
		free_templates = free_templates + ['pillar'] if !free_templates.include?('pillar')
		free_templates.each{ |ft| result << [ft.to_s.humanize, ft] }
		result.sort!
	end
end
