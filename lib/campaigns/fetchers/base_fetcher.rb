class CampaignDataFetcher
  class BaseFetcher

    attr :settings
    attr :logger

    def initialize(settings: nil)
      @settings = settings || {}
      @logger   = Logger.new("#{Rails.root}/log/fetch_data.log")
    end

    # @param [CampaignReport] blank report
    def fetch_and_save!(report)
      save!(fetch!(report))
    end

    # @param [CampaignReport] report blank report
    # @return [CampaignReport] filled report.dup
    def fetch!(report)
      raise NotImplementedError
    end

    # @param [CampaignReport] report filled report
    def save!(report)
      if report.date == :summary
        campaign_day = CampaignDay.find_or_initialize_by(
          campaign_id: report.campaign_id
        )
        campaign_day.date = Campaign.find(report.campaign_id).initial_date unless campaign_day.date
      else
        campaign_day = CampaignDay.find_or_initialize_by(
          campaign_id: report.campaign_id,
          date:        report.date
        )
      end
      campaign_day.spent      = report.spent if report.spent
      campaign_day.reached    = report.reached if report.reached
      campaign_day.converted  = report.converted if report.converted
      campaign_day.meta       = report.meta
      campaign_day.save!
    end
  end
end
