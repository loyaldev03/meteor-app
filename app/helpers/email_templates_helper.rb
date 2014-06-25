module EmailTemplatesHelper
	def template_types_options
		[
			['Birthday', 'birthday'],
			['Cancellation', 'cancellation'],
			# ['Active', 'active'],
			['Hard Decline', 'hard_decline'],
			['Manual Payment Prebill', 'manual_payment_prebill'],
			['Pillar', 'pillar'],
			['Prebill', 'prebill'],
			['Refund', 'refund'],
			['Rejection', 'rejection'],
			['Soft Decline', 'soft_decline']
		]
	end

	def clients_options
		[
			# ['Action Mailer', 'action_mailer'],
			['Exact Target', 'exact_target'],
			# ['Lyris ', 'lyris']
		]
	end
end
