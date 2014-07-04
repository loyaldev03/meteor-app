module EmailTemplatesHelper

	def clients_options
	clients = [ ['Exact Target', 'exact_target'] ]
	clients << ['Action Mailer', 'action_mailer'] unless Rails.env.production?
	end
	
	def template_types_options(tom_id, current_type)
		templates = [
			"birthday", 
			"cancellation", 
			"hard_decline", 
			"manual_payment_prebill", 
			"pillar", 
			"prebill", 
			"refund", 
			"rejection", 
			"soft_decline"
		]
		templates_used = TermsOfMembership.find(tom_id).email_templates.collect(&:template_type)
		result = []
		free_templates = templates - templates_used + Array(current_type)
		free_templates = free_templates + ['pillar'] if !free_templates.include?('pillar')
		free_templates.each{ |ft| result << [ft.humanize, ft] }
		result.sort!
	end
end
