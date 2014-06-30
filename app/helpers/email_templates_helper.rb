module EmailTemplatesHelper

	def clients_options
	[
		['Action Mailer', 'action_mailer'],
		['Exact Target', 'exact_target'],
		['Lyris ', 'lyris']
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
		templates_used_query = EmailTemplate.find_by_sql(["SELECT DISTINCT(template_type) FROM email_templates WHERE terms_of_membership_id = #{tom_id}"])
		templates_used = Array.new()
		templates_used_query.each do |tu|
			templates_used = templates_used + [tu.template_type]
		end
		result = Array.new()
		free_templates = templates - templates_used + Array(current_type)
		if !free_templates.include?('pillar')
			free_templates = free_templates + ['pillar']
		end
		free_templates.each do |ft|
			result << [ft.humanize, ft]
		end
		result.sort!
		result
	end
end
