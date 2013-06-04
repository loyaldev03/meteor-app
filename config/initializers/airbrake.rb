Airbrake.configure do |config|
  config.api_key = {
                    :project => 'sac-platform-2-platform', # the identifier you specified for your project in Redmine
                    :tracker => 'Bug',                           # the name of your Tracker of choice in Redmine
                    :api_key => 'xNACQ5h6rAei8ATXiSwS',            # the key you generated before in Redmine (NOT YOUR HOPTOAD API KEY!)
                    # :category => 'Development',                  # the name of a ticket category (optional.)
                    :assigned_to => 'platformissues',                     # the login of a user the ticket should get assigned to by default (optional.)
                    :priority => 5,                              # the default priority (use a number, not a name. optional.)
                    :environment => Rails.env                   # application environment, gets prepended to the issue's subject and is stored as a custom issue field. useful to distinguish errors on a test system from those on the production system (optional).
                    # :repository_root => '/some/path'             # this optional argument overrides the project wide repository root setting (see below).
                   }.to_yaml
  config.host = 'redmine.xagax.com'                            # the hostname your Redmine runs at
  config.port = 443                                              # the port your Redmine runs at
  config.secure = true                                           # sends data to your server via SSL (optional.)
end

ZENDESK_API_CLIENT = ZendeskAPI::Client.new do |config|
  config.username = "gustavo@xagax.com"
  config.password = "kjsa8703"
  config.url = "https://stoneacre.zendesk.com/api/v2"
end

# do not verify certificate
module Airbrake
  class Sender
    alias old_setup_http_connection setup_http_connection
    def setup_http_connection
      http = old_setup_http_connection
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE if http.use_ssl?
      http
    end
  end
end