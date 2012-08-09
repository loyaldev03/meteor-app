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

  desc "Send file to account updater. ONMC version"
  task :account_updater_send_file => :environment do
    ################################################
    ########## new file!
    ################################################
    local_filename = "#{RAILS_ROOT}/mes_account_updater_files/onmc_account_updater_#{Date.today}.txt"
    file = File.open(local_filename, 'w')

    # add header
    record_type, version_id, merchant_id = 'H1', '100000', "%-32s" % '941000110028'
    file.write [ record_type, version_id, merchant_id ].join + "\n"

    count = 0
    # members with expired credit card and active
    Member.find(:all, 
      :conditions => [ 
        " (active = 1 or trial = 1) and ((cc_month_exp <= ? and cc_year_exp = ?) or cc_year_exp < ?) ", 
        Date.today.month, Date.today.year, Date.today.year 
      ] , :limit => 10
    ).each do |member|
      
      ActiveMerchant::Billing::CreditCard.require_verification_value = false
      credit_card = ActiveMerchant::Billing::CreditCard.new(
        :number     => member.cc_number,
        :month      => member.cc_month_exp,
        :year       => member.cc_year_exp,
        :first_name => member.first_name,
        :last_name  => member.last_name
      )
      credit_card.valid?
      account_type = case credit_card.type
      when 
        'visa': 'VISA'
      when 
        'master': 'MC'
      else
        nil
      end
      # only master and visa allowed
      next if account_type.nil?

      # add cc line
      record_type, account_number, expiration_date, descretionary_data = 'D1', "%-32s" % member.cc_number, 
        member.cc_year_exp.to_s[2..3]+("%02d" % member.cc_month_exp), member.id

      file.write [ record_type, account_type, account_number, expiration_date, descretionary_data ].join + "\n"
      count += 1
    end

    # add trailer
    record_type, record_count = 'T1', "%06d" % count
    file.write [ record_type, record_count ].join
    file.close
    ################################################
    ########## new file!
    ################################################

    conn = Faraday.new(:url => 'https://www.merchante-solutions.com/', :ssl => {:verify => false}) do |builder|
      builder.request :multipart
    end
    merchant_id = '941000110028' # gateway.login[0..11]

    result = conn.post '/srv/api/ausUpload?', { 
      :userId => "#{merchant_id}AUS", 
      :userPass => 'Letmein123', 
      :merchId => merchant_id, 
      :attachment => Faraday::UploadIO.new(local_filename, 'application/x-www-form-urlencoded')
    }    
    lines = result.body.split("\n")
  end


end