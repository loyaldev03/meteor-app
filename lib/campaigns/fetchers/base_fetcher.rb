class CampaignDataFetcher
  class BaseFetcher

    attr :settings

    def initialize(settings: nil)
      @settings = settings || {}
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
        campaign_day.date = Campaign.find(report.campaign_id).starts_on unless campaign_day.date
      else
        campaign_day = CampaignDay.find_or_initialize_by(
          campaign_id: report.campaign_id,
          date:        report.date
        )
      end
      campaign_day.spent      = report.spent
      campaign_day.reached    = report.reached
      campaign_day.converted  = report.converted
      campaign_day.meta       = report.meta
      campaign_day.save!
    end
  end
end
