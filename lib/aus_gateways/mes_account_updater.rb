module MesAccountUpdater
  CHARGEBACKS_TO_NOT_PROCESS = [ 'Duplicate Processing' ]

  def self.process_chargebacks
    PaymentGatewayConfiguration.joins(:club).where(clubs: {billing_enable: true}).find_all_by_gateway('mes').each do |gateway|
      MesAccountUpdater.process_chargebacks_for_gateway gateway
    end
  end

  def self.account_updater_process_answers
    PaymentGatewayConfiguration.find_all_by_gateway('mes').each do |gateway|
      MesAccountUpdater.account_updater_process_answers_for_gateway gateway unless gateway.aus_login.blank?
    end
  end
  
  def self.account_updater_send_file_to_process
    PaymentGatewayConfiguration.find_all_by_gateway('mes').each do |gateway|
      MesAccountUpdater.account_updater_send_file_to_process_for_gateway gateway unless gateway.aus_login.blank?
    end
  end

  def self.process_chargebacks_for_gateway(gateway)
    conn = Faraday.new(:url => Settings.mes_report_service.url, :ssl => {:verify => false})
    initial_date, end_date = (Date.today - 1).strftime('%m/%d/%Y'), (Date.today - 1).strftime('%m/%d/%Y')
    result = conn.get Settings.mes_report_service.path, { 
      :userId => Settings.mes_report_service.user, 
      :userPass => Settings.mes_report_service.password, 
      :reportDateBegin => initial_date, 
      :reportDateEnd => end_date, 
      :nodeId => gateway.login[0..11], 
      :reportType => 1, 
      :includeTridentTranId => true, 
      :includePurchaseId => true, 
      :includeClientRefNum => true, 
      :dsReportId => 5
    }
    Rails.logger.info "[MesChargebackReport-#{(Date.today - 1).strftime('%m/%d/%Y')}] Processing file: #{result.body}"
    process_chargebacks_result(result.body, gateway) if result.success?
  end 


  ################################################
  ########## AUS new file! #######################
  ################################################
  def self.account_updater_process_answers_for_gateway(gateway)
    return if gateway.aus_login.nil? or gateway.aus_password.nil?
    answer = prepare_connection '/srv/api/ausStatus?', { :statusFilter => 'NEW' }, gateway
    quantity = answer['statusCount'].to_i-1
    if quantity >= 0
      0.upto(quantity) do |i|
        request_file_by_id answer["rspfId_#{i}"], "#{gateway.club_id}-rsp-"+answer["reqfId_#{i}"]+"-#{Time.now.to_i}.txt", gateway
      end
      send_email_with_call_users(gateway.club.payment_gateway_errors_email)
    end
  end

  def self.account_updater_send_file_to_process_for_gateway(gateway)
    return if gateway.aus_login.nil? or gateway.aus_password.nil?
    local_filename = "#{Settings.mes_aus_service.folder}/#{gateway.club_id}_account_updater_#{Time.zone.now}.txt"
    send_file_to_mes(local_filename, gateway) if store_file(local_filename, gateway)
  end

  private
    def self.send_email_with_call_users(contact_email_list)
      ccs = CreditCard.where([" aus_status = 'CALL' AND date(aus_answered_at) = ? ", Time.zone.now.to_date ])
      if ccs.size > 0
        csv = "id,first_name,last_name,email,phone,status,cs_next_bill_date\n"
        csv += ccs.collect {|cc| [ cc.user_id, cc.user.first_name, cc.user.last_name, cc.user.email, cc.user.full_phone_number,
            cc.user.status, cc.user.next_retry_bill_date ].join(',') }.join("\n")
        Notifier.call_these_users(csv,contact_email_list).deliver
      end
    end

    def self.send_file_to_mes(local_filename, gateway)
      conn = Faraday.new(:url => Settings.mes_aus_service.url, :ssl => {:verify => false}) do |builder|
        builder.request :multipart
        builder.adapter Faraday.default_adapter  # make requests with Net::HTTP  
      end

      payload = {}
      payload[:file] = Faraday::UploadIO.new(local_filename, 'multipart/form-data')
      payload[:userId] = gateway.aus_login
      payload[:userPass] = gateway.aus_password
      payload[:merchId] = gateway.aus_login[0..11]

      result = conn.post '/srv/api/ausUpload', payload
      answer = Rack::Utils.parse_nested_query(result.body)

      Rails.logger.info answer.inspect
    end

    def self.store_file(local_filename, gateway)
      file = File.open(local_filename, 'w')

      # add header
      record_type, version_id, merchant_id = 'H1', '100000', "%-32s" % gateway.aus_login[0..11]
      file.write [ record_type, version_id, merchant_id ].join + "\n"

      count = 0
      # members with expired credit card and active
      users = User.billable.where([ 'date(bill_date) = ? AND club_id = ?', 
                    (Time.zone.now+7.days).to_date, gateway.club_id ])
      users.each do |user|
        cc = user.active_credit_card
        account_type = case cc.cc_type
        when 'visa'
          'VISA'
        when 'master'
          'MC  '
        else
          nil
        end
        # only master and visa allowed
        next if account_type.nil?

        cc.aus_sent_at = Time.zone.now
        cc.save

        # add cc line
        record_type, account_token, expiration_date, descretionary_data = 'D2', "%-32s" % cc.token.strip, 
            cc.expire_year.to_s[2..3]+("%02d" % cc.expire_month), "CC%-30s"% cc.id

        file.write [ record_type, account_type, account_token, expiration_date, descretionary_data ].join + "\n"
        count += 1
      end

      # add trailer
      record_type, record_count = 'T1', "%06d" % count
      file.write [ record_type, record_count ].join
      file.close
      count != 0
    end

    def self.prepare_connection(path, options = {}, gateway = nil)
      conn = Faraday.new(:url => Settings.mes_aus_service.url, :ssl => {:verify => false})
      result = conn.get path, { 
        :userId => gateway.aus_login, 
        :userPass => gateway.aus_password, 
        :merchId => gateway.aus_login[0..11]
      }.merge(options)
      answer = Rack::Utils.parse_nested_query(result.body)
    end

    def self.request_file_by_id(file_id, filename, gateway)
      answer = prepare_connection '/srv/api/ausDownload?', { :rspfId => file_id }, gateway
      if answer['rspCode'].to_i == 0
        full_filename = "#{Settings.mes_aus_service.folder}/#{filename}"
        file = File.open(full_filename, 'w')
        file.write answer.first[0]
        file.close
        parse_file full_filename, gateway.club_id
      end
    end

    def self.parse_file(filename, club_id)
      File.open(filename).each do |line|
        # do not parse header or trailers.
        next if line[0..0] == 'H' or line[0..0] == 'T'
        # TODO: IMPROVEMENT: we can add a flag on each credit card to know if it was or nor processed
        record_type = line[0..1]
        old_account_type = line[2..5]
        old_account_token = line[6..37].strip
        old_expiration_date = line[38..41]
        new_account_type = line[42..45]
        new_account_type_am = case new_account_type
        when 'VISA'
          'visa'
        when 'MC'
          'master'
        else
          'unknown'
        end
        new_account_number= line[46..77].strip
        new_expiration_date = line[78..81]
        response_code = line[82..89].strip
        response_source = line[90..91]
        discretionary_data = line[92..123]

        credit_card = CreditCard.find(discretionary_data[2..32].strip)
        if credit_card.nil?
          Rails.logger.info "CreditCard id not found ##{discretionary_data} while parsing. #{line}"
        else
          new_expire_year = new_expiration_date[0..1].to_i+2000
          new_expire_month = new_expiration_date[2..3]
          credit_cards = CreditCard.find_all_by_token old_account_token
          credit_cards.each do |cc|
            if cc.active 
              if cc.aus_status.nil?
                cc.aus_answered_at = Time.zone.now
                cc.aus_status = response_code
                cc.save
              end
              case response_code
              when 'NEWACCT'
                new_credit_card = CreditCard.new(number: new_account_number, expire_year: new_expire_year, expire_month: new_expire_month)
                new_credit_card.token = old_account_token
                new_credit_card.cc_type = new_account_type_am
                answer = cc.user.add_new_credit_card(new_credit_card)
                unless answer[:code] == Settings.error_codes.success
                  Auditory.report_issue("MES::aus_update_process", response_code, { :credit_card => cc.inspect, :answer => answer, :line => line })
                end
              when 'NEWEXP'
                Auditory.audit(nil, cc, "AUS expiration update from #{cc.expire_month}/#{cc.expire_year} to #{new_expire_month}/#{new_expire_year}", cc.user, Settings.operation_types.aus_recycle_credit_card)
                cc.update_attributes :expire_year => new_expire_year, :expire_month => new_expire_month
              when 'CLOSED', 'CALL'
                user = cc.user
                unless user.lapsed?
                  user.cancel! Time.zone.now, "Automatic cancellation. AUS answered account #{response_code} wont be able to bill"
                  user.set_as_canceled!
                end
              else
                Rails.logger.info "CreditCard id ##{discretionary_data} with response #{response_code} ask for an action. #{line}"
              end
            end
          end
        end
      end
    end    


    def self.process_chargebacks_result(body, gateway)
      return if body.include?('Export Failed')
      lines = body.split("\n")
      lines.each do |line|
        columns = line.split(',')
        next if columns[0].include?('Merchant Id')
        columns.each { |x| x.gsub!('"', '') }
        args = { :control_number => columns[2], :incomming_date => columns[3],
          :reference_number => columns[5].gsub("'", ''), :transaction_date => columns[6], :transaction_amount => columns[7],
          :trident_transaction_id => columns[8], :purchase_transaction_id => columns[9],
          :client_reference_number => columns[10], :auth_code => columns[11],
          :adjudication_date => columns[12], :adjudication_number => columns[13],
          :reason => columns[14], :first_time => columns[15],
          :reason_code => columns[16], :cb_ref_number => columns[17]
        }
        next if MesAccountUpdater::CHARGEBACKS_TO_NOT_PROCESS.include?(args[:reason]) or args[:adjudication_date].blank?
        transaction_chargebacked = Transaction.find_by_payment_gateway_configuration_id_and_response_transaction_id gateway.id, args[:trident_transaction_id]
        user = User.find_by_id_and_club_id(args[:client_reference_number], gateway.club_id)
        begin
          if transaction_chargebacked.nil?
            raise "Chargeback ##{args[:control_number]} could not be processed. user or transaction_chargebacked are null! #{line}"
          elsif user.nil?
            transaction_chargebacked.user.chargeback! transaction_chargebacked, args
          elsif transaction_chargebacked.user_id == user.id
            user.chargeback! transaction_chargebacked, args
          else
            raise "Chargeback ##{args[:control_number]} could not be processed. user and transaction_chargebacked are different! #{line}"
          end
        rescue 
          Auditory.report_issue("MES::chargeback_report", $!, { :gateway_id => gateway.id.to_s, :user => user.inspect, :line => line, :transaction_chargebacked_id => transaction_chargebacked.id.to_s })
          Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
        end
      end
    end      

end
