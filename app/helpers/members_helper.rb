module UsersHelper
  def user_action_drop_menu(current_user)
    js_confirm = "return confirm(\"Continue?\");"
    html = ""
    html << "<div class='btn-group'>"
    html << "<a href='#' data-toggle='dropdown' class='btn dropdown-toggle'>Actions<span class='caret'></span></a>"
    html << "<ul class='dropdown-menu'>"
    unless current_user.blacklisted?
      html << "<li><a onclick='#{js_confirm}' href='#{user_blacklist_path(:user_prefix => current_user.id)}'>#{t('buttons.blacklist')}</a></li>"
    end
    if current_user.can_be_canceled?
      html << "<li><a onclick='#{js_confirm}' href='#{user_cancel_path(:user_prefix => current_user.id)}'>#{t('buttons.cancel')}</a></li>"
    end
    unless current_user.api_id.nil? 
      html << "<li><a onclick='#{js_confirm}' href= #{user_resend_welcome_path(:user_prefix => current_user.id)} data-method='post' >#{t('buttons.resend_welcome_email')}</a></li>"
      html << "<li><a onclick='#{js_confirm}' href= #{user_reset_password_path(:user_prefix => current_user.id)} data-method='post'>#{t('buttons.password_reset')}</a></li>"
    end
    html << "</ul>"
    html << "</div>"
    raw(html)
  end

  def user_status_class(current_user)
    text = ""
    if current_user.lapsed?
      text = "btn-danger"
    elsif current_user.active?
      text = "btn-success"
    else
      text = "btn-warning"
    end
  end
end
