namespace :mes do
  desc "get chargeback report"
  task :chargeback_report => :environment do
    PaymentGatewayConfiguration.find_all_by_gateway_and_mode('mes', 'production').each do |gateway|
      conn = Faraday.new(:url => Settings.mes_report_service.url, :ssl => {:verify => false})

      day = (Date.today - 1.days).strftime('%m/%d/%Y')
      merchant_id = gateway.login[0..11]

      result = conn.get Settings.mes_report_service.path, { 
        :userId => Settings.mes_report_service.user, 
        :userPass => Settings.mes_report_service.password, 
        :reportDateBegin => day, 
        :reportDateEnd => day, 
        :nodeId => merchant_id, 
        :reportType => 1, 
        :includeTridentTranId => true, 
        :includePurchaseId => true, 
        :includeClientRefNum => true, 
        :dsReportId => 5
      }
      lines = result.body.split("\n")
      lines.each do |line|
        # => [ [""Merchant Id"", ""DBA Name"", ""Control Number"", ""Incoming Date"", ""Card Number"", 
        #   ""Reference Number"", ""Tran Date"", ""Tran Amount"", ""Trident Tran ID"", ""Purchase ID"", 
        #   ""Client Ref Num"", ""Auth Code"", ""Adj Date"", ""Adj Ref Num"", ""Reason"", ""First Time"", 
        #   ""Reason Code"", ""CB Ref Num"", ""Terminal ID""], 
        # ["941000110030", ""SAC*AO ADVENTURE CLUB"", "2890810", "07/26/2012", "514922xxxxxx1664", 
        #   "'25247702125003734750438", "05/03/2012", "84.0", "8c7ccb99e132368c98b0bdf954a4b9c5", "3854832", 
        #   ""3854832"", "00465Z", ""07/27/2012-"", ""00373475043"", ""No Cardholder Authorization"", "Y", "4837", 
        #   "2206290194", ""94100011003000000002""] ] 
        columns = line.split(',')
        next if columns[0].include?('Merchant Id')
        control_number = columns[2]
        incomming_date = columns[3]
        card_number = columns[4]
        reference_number = columns[5]
        transaction_date = columns[6]
        transaction_amount = columns[7]
        trident_transaction_id = columns[8]
        purchase_transaction_id = columns[9]
        client_reference_number = columns[10]
        auth_code = columns[11]
        adjudication_date = columns[12]
        adjudication_number = columns[13]
        reason = columns[14]
        first_time = columns[15]
        reason_code = columns[16]
        cb_ref_number = columns[17]
        member = Member.find()
        member.chargeback! reason
      end
    end
  end

  desc "Send file to account updater. ONMC version"
  task :account_updater_send_file => :environment do
      # TODO:
  end


end