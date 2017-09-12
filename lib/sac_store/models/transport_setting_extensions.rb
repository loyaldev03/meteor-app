module SacStore
  module TransportSettingExtensions

    def self.included(base)
      base.send :include, InstanceMethods
    end

    module InstanceMethods
      def test_store_connection
        answer = { success: false, message: I18n.t('error_messages.transport_setting_wrong_credentials') }
        if store_spree? and credentials_correctly_configured? and settings and settings['url'] and settings['api_token'].present?
          response  = SacStore.client(settings[:url]).post VARIANTS_URL, { api_key: settings['api_token'], page: 1 }
          answer    = { success: true, message: 'Phoenix can connect to Store API correctly.' } if response and response.status == 200 and response.body.code == 200
        end
        answer
      rescue Faraday::ConnectionFailed, URI::BadURIError
        answer 
      rescue Exception => e
        Auditory.report_issue("SacStore::TransportSettingsExtensions::test_stroe_connection", e, { club_id: club_id, settings: settings })
        { success: false, message: I18n.t('error_messages.airbrake_error_message') }
      end
    end
  end
end