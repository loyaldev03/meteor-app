Tire.configure do
  url    Settings.elasticsearch.url
  logger 'log/elasticsearch.log', :level => 'debug' if ["prototype", "staging", "production"].include? Rails.env
end
