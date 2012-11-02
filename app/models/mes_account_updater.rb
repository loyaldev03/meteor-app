class MesAccountUpdater
  def self.process_chargebacks(gateway)
    conn = Faraday.new(:url => Settings.mes_report_service.url, :ssl => {:verify => false})
    initial_date, end_date = (Date.today - 1.days).strftime('%m/%d/%Y'), (Date.today - 1.days).strftime('%m/%d/%Y')
    result = conn.get Settings.mes_report_service.path, { 
      :userId => gateway.aus_login, 
      :userPass => gateway.aus_password, 
      :reportDateBegin => initial_date, 
      :reportDateEnd => end_date, 
      :nodeId => gateway.merchant_key, 
      :reportType => 1, 
      :includeTridentTranId => true, 
      :includePurchaseId => true, 
      :includeClientRefNum => true, 
      :dsReportId => 5
    }
    process_chargebacks_result(result.body, gateway) if result.success?
  end 


  ################################################
  ########## AUS new file! #######################
  ################################################
  def self.account_updater_process_answers(gateway)
    answer = prepare_connection '/srv/api/ausStatus?', { :statusFilter => 'NEW' }, gateway
    0.upto(answer['statusCount'].to_i-1) do |i|
      request_file_by_id answer["rspfId_#{i}"], "rsp-"+answer["reqfId_#{i}"]+"-#{Time.now.to_i}.txt", gateway
    end
    send_email_with_call_members
  end

  def self.account_updater_send_file_to_process(gateway)
    local_filename = "#{Settings.mes_aus_service.folder}/#{gateway.club_id}_account_updater_#{Time.zone.now}.txt"
    store_file local_filename, gateway
    send_file_to_mes local_filename, gateway
  end

  private
    def self.send_email_with_call_members
      ccs = CreditCard.where([" aus_status = 'CALL' AND date(aus_answered_at) = ? ", Time.zone.now.to_date ])
      csv = "id,first_name,last_name,email,phone,status,cs_next_bill_date\n"
      csv += ccs.collect {|cc| [ cc.member_id, cc.member.first_name, cc.member.last_name, cc.email, cc.full_phone_number,
          cc.member.status, cc.member.next_retry_bill_date ].join(',') }.join("\n")
      Notifier.call_these_members(csv).deliver
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
      payload[:merchId] = gateway.merchant_key

      result = conn.post '/srv/api/ausUpload', payload
      answer = Rack::Utils.parse_nested_query(result.body)

      Rails.logger.info answer.inspect
    end

    def self.store_file(local_filename, gateway)
      file = File.open(local_filename, 'w')

      # add header
      record_type, version_id, merchant_id = 'H1', '100000', "%-32s" % gateway.merchant_key
      file.write [ record_type, version_id, merchant_id ].join + "\n"

      count = 0
      # members with expired credit card and active
      members = Member.joins(:credit_cards).where([ ' date(members.bill_date) = ? AND credit_cards.active = 1 ' + 
                    ' AND (credit_cards.aus_sent_at IS NULL OR (credit_cards.aus_sent_at < ? AND credit_cards.aus_status IS NULL) )', 
                    (Time.zone.now+7.days).to_date,
                    (Time.zone.now-1.days).to_date ])
      members.each do |member|
        cc = member.active_credit_card
        credit_card = cc.am_card
        credit_card.valid?
        account_type = case credit_card.type
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
        record_type, account_number, expiration_date, descretionary_data = 'D1', "%-32s" % cc.number.strip, 
            cc.expire_year.to_s[2..3]+("%02d" % cc.expire_month), "CC%-30s"% cc.id

        file.write [ record_type, account_type, account_number, expiration_date, descretionary_data ].join + "\n"
        count += 1
      end

      # add trailer
      record_type, record_count = 'T1', "%06d" % count
      file.write [ record_type, record_count ].join
      file.close
    end

    def self.prepare_connection(path, options = {}, gateway = nil)
      conn = Faraday.new(:url => Settings.mes_aus_service.url, :ssl => {:verify => false})
      result = conn.get path, { 
        :userId => gateway.aus_login, 
        :userPass => gateway.aus_password, 
        :merchId => gateway.merchant_key 
      }.merge(options)
      answer = Rack::Utils.parse_nested_query(result.body)
    end

    def self.request_file_by_id(file_id, filename, gateway)
      answer = prepare_connection '/srv/api/ausDownload?', { :rspfId => file_id }, gateway
      if answer['rspCode'].to_i == 0
        full_filename = "#{Settings.mes_aus_service.folder}/#{filename}"
        file = File.open(full_filename, 'w')
        file.write answer
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
        old_account_number = line[6..37].strip
        old_expiration_date = line[38..41]
        new_account_type = line[42..45]
        new_account_number = line[46..77].strip
        new_expiration_date = line[78..81]
        response_code = line[82..89].strip
        response_source = line[90..91]
        discretionary_data = line[92..123]

        credit_card = CreditCard.find(discretionary_data[2..32].strip)
        if credit_card.nil?
          Rails.logger.info "CreditCard id not found ##{discretionary_data} while parsing. #{line}"
        else
          credit_cards = CreditCard.find_all_by_encrypted_number credit_card.encrypted_number
          credit_cards.each do |cc|
            cc.update_attributes :aus_answered_at => Time.zone.now, :aus_status => response_code if cc.aus_status.nil?
            if credit_card.active 
              case response_code
              when 'NEWACCT'
                CreditCard.new_active_credit_card(credit_card, new_expiration_date[0..1].to_i+2000, new_expiration_date[2..3], new_account_number)
              when 'NEWEXP'
                CreditCard.new_active_credit_card(credit_card, new_expiration_date[0..1].to_i+2000, new_expiration_date[2..3])
              when 'CLOSED', 'CALL'
                credit_card.member.cancel! Time.zone.now, "Automatic cancellation. AUS answered account #{response_code} wont be able to bill"
              else
                Rails.logger.info "CreditCard id ##{discretionary_data} with response #{response_code} ask for an action. #{line}"
              end
            end
          end
        end
      end
    end    

    def self.process_chargebacks_result(body, gateway)
      body.split("\n").each do |line|
        columns = line.split(',')
        next if columns[0].include?('Merchant Id')
        columns.each { |x| x.gsub!('"', '') }
        args = { :control_number => columns[2], :incomming_date => columns[3],
          :reference_number => columns[5], :transaction_date => columns[6], :transaction_amount => columns[7],
          :trident_transaction_id => columns[8], :purchase_transaction_id => columns[9],
          :client_reference_number => columns[10], :auth_code => columns[11],
          :adjudication_date => columns[12], :adjudication_number => columns[13],
          :reason => columns[14], :first_time => columns[15],
          :reason_code => columns[16], :cb_ref_number => columns[17]
        }
        transaction_chargebacked = Transaction.find_by_payment_gateway_configuration_id_and_response_transaction_id gateway.id, args[:trident_transaction_id]
        member = Member.find_by_visible_id_and_club_id(args[:client_reference_number], gateway.club_id)
        begin
          if transaction_chargebacked.member_id == member.id
            member.chargeback! transaction_chargebacked, args
            member.save
          else
            raise "Chargeback ##{args[:control_number]} could not be processed. member and transaction_chargebacked are different! #{line}"
          end
        rescue 
          Airbrake.notify(:error_class => "MES::chargeback_report", :parameters => { :member => member.inspect })
          Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
        end
      end
    end      

end