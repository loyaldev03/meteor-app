module TermsOfMembershipsHelper
	def select_date_span(select_name)
		dates_span = [['Month(s)', 'months'], ['Day(s)', 'days']]
		select_tag select_name, options_for_select(dates_span), :class => 'input-small'
	end
end
