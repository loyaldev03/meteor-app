module ApplicationHelper
  def twitterized_type(type)
    case type.to_sym
      when :alert
        "alert alert-block"
      when :error
        "alert alert-error"
      when :notice
        "alert alert-info"
      when :success
        "alert alert-success"
      else
        type.to_s
    end
  end 

  def fulfillment_selectable_statuses(name, selected = nil, allow_blank = false)
    @possible_status = (allow_blank ? [''] : []) + Fulfillment.state_machines[:status].states.map(&:name).delete_if{ |state| state == :canceled }
    select_tag name, options_for_select(@possible_status, :selected => selected), :class => 'select_field input-medium' 
  end

  def user_selectable_statuses(name, selected = nil, allow_blank = false)
    @possible_status = (allow_blank ? [''] : []) + User.state_machines[:status].states.map(&:name).delete_if{ |state| state == :none }
    select_tag name, options_for_select(@possible_status, :selected => selected), :class => 'select_field input-medium' 
  end

  def sortable(column, title = nil)
    title ||= column.titleize
    css_class = (column == @sort_column ? ( @sort_direction == "asc" ? 'icon-arrow-down' : 'icon-arrow-up') : nil)
    direction = column == @sort_column && @sort_direction == "asc" ? "desc" : "asc"
    page = params[:page] || 1
    user_search = params[:user] ? { :user => params[:user] } : { }
    link_to title, {:sort => column, :direction => direction, :page => page}.merge(user_search), {:class => css_class}
  end 

  def dynamic_form_error_messages(object)
    return '' unless object.respond_to?(:errors) && object.errors.any?

    errors_list = ""
    errors_list << content_tag(:span, "There are errors!", :class => "title-error")
    errors_list << object.errors.map { |field, message| content_tag(:li, field.to_s + ": " + message.first) }.join("\n")

    '<div class="alert alert-danger"><ul>'+errors_list.html_safe+'</ul></div>'
  end
end
