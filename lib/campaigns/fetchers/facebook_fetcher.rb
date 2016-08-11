class CampaignDataFetcher
  class FacebookFetcher < BaseFetcher
    # API: https://developers.facebook.com/docs/marketing-api/insights/fields/v2.7
    # reached = impressions
    # converted = clicks
    # spent = spend

    def fetch!(report)
      @report               = report.dup
      @report.date          = (report.date || Time.current.yesterday).to_date
      report_data           = data
      if report_data
        if report_data[:impressions] and report_data[:clicks] and report_data[:spend]
          @report.reached   = report_data.impressions
          @report.converted = report_data.clicks
          @report.spent     = report_data.spend
        end
        @report.meta        = report_data["meta"] || :no_error
      end
      @report
    end

    private

      def missing_required_credentials?
        @settings["client_id"].blank? or @settings["client_secret"].blank?
      end

      def access_token
        @access_token ||= @settings["access_token"]
      end

      def date
        @date ||= @report.date.strftime("%Y-%m-%d")
      end

      def url
        params = ["time_range={'since':'#{date}','until':'#{date}'}",
          "fields=spend,impressions,clicks",
          "access_token=#{access_token}"].join('&')
        [ "v2.7",
          @report.campaign_foreign_id.to_s,
          "insights"
        ].join("/") + "?" + params
      end

      def connection
        @connection ||= Faraday.new(url: 'https://graph.facebook.com', :ssl => { :verify => true }) do |builder|
          builder.request  :json
          builder.response :mashify
          builder.response :json, :content_type => /\bjson$/
          builder.adapter  Faraday.default_adapter
        end
      end

      def proceed_with_error_logic(response)
        case(response.body.error.code)
          when 100, 803
            Hashie::Mash.new('meta' => :invalid_campaign)
          when 104, 190
            Hashie::Mash.new('meta' => :unauthorized)
          when 2635
            raise FbGraph2::Exception::InvalidRequest.new(response.body.error.message)
        end
      end

      def data
        if missing_required_credentials?
          Hashie::Mash.new('meta' => :unauthorized)
        elsif access_token.blank?
          Hashie::Mash.new('meta' => :unauthorized)
        else
          response = connection.get(url)
          response.status == 200 ? response.body.data.first : proceed_with_error_logic(response)
        end
      end
  end
end