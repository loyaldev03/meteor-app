class CampaignDataFetcher

  CampaignReport = Struct.new(
    :campaign_id,
    :campaign_foreign_id,
    :transport,
    :date,
    :spent,
    :reached,
    :converted,
    :meta
  )
  
  autoload :BaseFetcher, File.expand_path('../fetchers/base_fetcher', __FILE__)
  autoload :FacebookFetcher, File.expand_path('../fetchers/facebook_fetcher', __FILE__)


  def initialize(club_id:, transport:, date:)
    @club_id    = club_id
    @transport  = transport
    @date       = date
  end

  def fetch!
    unless Campaign.transports.keys.to_set.include?(@transport)
      raise "unknown transport: #{@transport.inspect}"
    end
    report_template           = CampaignReport.new
    report_template.transport = @transport
    report_template.date      = @date
    campaigns.find_each do |campaign|
      report                     = report_template.dup
      report.campaign_id         = campaign.id
      report.campaign_foreign_id = campaign.transport_campaign_id
      if block_given?
        # may be used for queueing tasks
        yield report
      else
        fetcher.fetch_and_save!(report)
      end
    end
    nil
  end

  private

  def campaigns
    Campaign.where(club_id: @club_id).by_transport(@transport).active(@date)
  end

  def fetcher
    @fetcher ||= begin
      fetcher_class.new(settings: settings)
    end
  end

  def fetcher_class
    @fetcher_class ||= self.class.const_get("#{@transport.split('_').map(&:capitalize).join}Fetcher")
  end

  def settings
    @settings ||= begin
      settings = TransportSetting.where(club_id: @club_id).by_transport(@transport).first
      settings.try(:settings)
    end
  end
end