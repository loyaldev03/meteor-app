module EmailTemplatesHelper

	def clients_options
	[
		# ['Action Mailer', 'action_mailer'],
		['Exact Target', 'exact_target'],
		# ['Lyris ', 'lyris']
	]
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
