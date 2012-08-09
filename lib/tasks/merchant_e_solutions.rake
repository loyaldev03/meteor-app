namespace :mes do
  desc "get chargeback report"
  task :chargeback_report => :environment do
    PaymentGatewayConfiguration.find_all_by_gateway_and_mode('mes', 'production').each do |gateway|
      conn = Faraday.new(:url => Settings.mes_report_service.url, :ssl => {:verify => false})
      ## GET ##
      initial_date = (Date.today - 7.days).strftime('%m/%d/%Y')
      end_date = Date.today.strftime('%m/%d/%Y')
      merchant_id = gateway.login[0..11]

      result = conn.get Settings.mes_report_service.path, { 
        :userId => Settings.mes_report_service.user, 
        :userPass => Settings.mes_report_service.password, 
        :reportDateBegin => initial_date, 
        :reportDateEnd => end_date, 
        :nodeId => merchant_id, 
        :reportType => 1, 
        :includeTridentTranId => true, 
        :includePurchaseId => true, 
        :includeClientRefNum => true, 
        :dsReportId => 5
      }
      lines = result.body.split("\n")
      lines.each do |line|
        line.split(',')
      end
    end
  end
end