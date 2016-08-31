class CampaignDataFetcher
  class MailchimpFetcher < BaseFetcher
    # API: https://apidocs.mailchimp.com/api/2.0/reports/summary.php
    # reached = emails_sent,
    # converted = unique_clicks
    # spent = 0 (since there is no need to track this field automatically or manually).

    # campaign_foreign_id is not the id shown in the web, but a different one (which is alphanumeric)
    # This is because Mailchimp works with two different IDs, one for the web and another one for api calls

    def fetch!(report)
      report            = report.dup
      report.date       = :summary
      data              = client.reports(report.campaign_foreign_id).retrieve
      report.reached    = data['emails_sent'].to_i
      report.converted  = data['clicks']['unique_subscriber_clicks'].to_i
      report.spent      = 0
      report.meta       = :no_error
      report
    rescue Gibbon::GibbonError
      report.meta       = :unauthorized
      report
    rescue Gibbon::MailChimpError
      report.meta       = :invalid_campaign
      report
    rescue Exception => e
      Auditory.report_issue("MailchimpFetcher campaign retrieval error.", 'Mailchimp returned an unexpected error', {exception: e.to_s}, false)
      @logger.error "MailchimpFetcher Error: #{e.to_s}"
      report.meta       = :unexpected_error
      report
    end

    private
      def client
        Gibbon::Request.new(api_key: settings['api_key'].to_s)
      end
  end
end
