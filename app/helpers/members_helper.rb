module MembersHelper
  def member_action_drop_menu(current_member)
    js_confirm = "return confirm(\"Continue?\");"
    html = ""
    html << "<div class='btn-group'>"
    html << "<a href='#' data-toggle='dropdown' class='btn dropdown-toggle'>Actions<span class='caret'></span></a>"
    html << "<ul class='dropdown-menu'>"
    unless current_member.blacklisted?
      html << "<li><a onclick='#{js_confirm}' href='#{member_blacklist_path(:member_prefix => current_member.id)}'>#{t('buttons.blacklist')}</a></li>"
    end
    if current_member.can_be_canceled?
      html << "<li><a onclick='#{js_confirm}' href='#{member_cancel_path(:member_prefix => current_member.id)}'>#{t('buttons.cancel')}</a></li>"
    end
    unless current_member.api_id.nil? 
      html << "<li><a onclick='#{js_confirm}' href= #{member_resend_welcome_path(:member_prefix => current_member.id)} data-method='post' >#{t('buttons.resend_welcome_email')}</a></li>"
      html << "<li><a onclick='#{js_confirm}' href= #{member_reset_password_path(:member_prefix => current_member.id)} data-method='post'>#{t('buttons.password_reset')}</a></li>"
    end
    html << "</ul>"
    html << "</div>"
    raw(html)
  end

  def menber_status_class(current_member)
    text = ""
    if current_member.lapsed?
      text = "btn-danger"
    elsif current_member.active?
      text = "btn-success"
    else
      text = "btn-warning"
    end
  end
end
