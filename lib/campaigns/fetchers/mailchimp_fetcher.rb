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
      response          = client.reports(report.campaign_foreign_id).retrieve
      data              = response.body
      report.reached    = data['emails_sent'].to_i
      report.converted  = data['clicks']['unique_subscriber_clicks'].to_i
      report.spent      = 0
      report.meta       = :no_error
      report
    rescue Gibbon::MailChimpError => e
      case e.body['status']
      when 401
        report.meta = :unauthorized
      when 404
        report.meta = :invalid_campaign
      else
        Auditory.report_issue('MailchimpFetcher: Mailchimp returned an unexpected code', nil, { response: e.body, campaign_id: report.campaign_id })
        report.meta = :unexpected_error
      end
      report
    rescue Exception => e
      Auditory.report_issue('MailchimpFetcher: Mailchimp returned an unexpected error', nil, { exception: e.to_s, campaign_id: report.campaign_id })
      Rails.logger.error "MailchimpFetcher Error: #{e.to_s}"
      report.meta = :unexpected_error
      report
    end

    private
      def client
        Gibbon::Request.new(api_key: settings['api_key'].to_s)
      end
  end
end
