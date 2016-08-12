module TransportSettingsHelper
  def nice_settings(settings)
    data = []
    settings.each do |key, value|
      data << "#{key.humanize} = \"#{value}\""
    end
    data.join('<br />').html_safe
  end
end
