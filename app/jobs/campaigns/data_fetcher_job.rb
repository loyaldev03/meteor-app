module Campaigns
  class DataFetcherJob < ActiveJob::Base
    queue_as :campaigns

    def perform(club_id, transport, date)
      CampaignDataFetcher.new(club_id: club_id, transport: transport, date: date).fetch!
    end
  end
end