module TermsOfMembershipsHelper
	def select_for_date_span(select_name, selected_item = nil)
		dates_span = options_for_select([['Day(s)', 'days'], ['Month(s)', 'months']], selected_item)
		select_tag select_name, dates_span, :class => 'input-small', :selected => selected_item
	end

	def select_for_toms(select_name, selected_item = nil)
		toms = TermsOfMembership.where(:club_id => @current_club.id)
		select_tag select_name, options_from_collection_for_select(toms, "id", "name", selected_item), :include_blank => true
	end

	def wizard_steps_indicator(current_step)
		class_for_selected = ' step_selected'
		html = ''
		html << '<h3 class="wizard_step">'
		html << '<span>Step </span>'
		(1..3).each do |s| 
			html << '<span class="wizard_step_circle' + (s == current_step ? class_for_selected : '') + '">' + s.to_s + '</span>'
		end 
    html << '</h3>'
    html.html_safe
	end

end
