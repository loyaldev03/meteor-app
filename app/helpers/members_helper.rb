module MembersHelper
	def member_action_drop_menu(current_member)
		js_confirm = "return confirm(\"Continue?\");"
		html = ""
		html << "<div class='btn-group'>"
        html << "<a href='#' data-toggle='dropdown' class='btn dropdown-toggle'>Actions<span class='caret'></span></a>"
        html << "<ul class='dropdown-menu'>"
        unless current_member.blacklisted?
    			html << "<li><a onclick='#{js_confirm}' href='#{member_blacklist_path(:member_prefix => current_member.visible_id)}'>Blacklist</a></li>"
        end
        if current_member.can_be_canceled?
        	html << "<li><a onclick='#{js_confirm}' href='#{member_cancel_path(:member_prefix => current_member.visible_id)}'>Cancel</a></li>"
        end
        html << "<li><a onclick='#{js_confirm}' href='#'>Resend welcome email</a></li>"
        html << "<li><a onclick='#{js_confirm}' href='#'>Password reset</a></li>"
        html << "</ul>"
        html << "</div>"
		return raw(html)
	end

    def menber_status_class(current_member)
        text = ""
        if current_member.lapsed?
            text = "red"
        elsif current_member.active?
            text = "ligthgreen"
        elsif
            text = "yellow"
        end
        text + "#{(current_member.blacklisted? ? "Blist" : "")}"
    end
end
