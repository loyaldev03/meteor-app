module ApplicationHelper
  def twitterized_type(type)
    case type
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
end
