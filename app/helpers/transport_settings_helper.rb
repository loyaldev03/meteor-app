module TransportSettingsHelper
  def nice_settings(settings)
    data = []
    settings.each do |key, value|
      data << "#{key}: <b>#{value}</b>"
    end
    data.join('<br />').html_safe
  end
end
