module TermsOfMembershipsHelper
	def select_for_date_span(select_name)
		dates_span = [['Month(s)', 'months'], ['Day(s)', 'days']]
		select_tag select_name, options_for_select(dates_span), :class => 'input-small'
	end

	def select_for_toms(select_name)
		toms = TermsOfMembership.where(:club_id => @current_club.id)
		select_tag select_name, options_from_collection_for_select(toms, "id", "name"), :include_blank => true
	end

end
