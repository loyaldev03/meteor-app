class MesAccountUpdater
  def self.process_chargebacks(gateway)
    conn = Faraday.new(:url => Settings.mes_report_service.url, :ssl => {:verify => false})
    initial_date, end_date = (Date.today - 1.days).strftime('%m/%d/%Y'), (Date.today - 1.days).strftime('%m/%d/%Y')
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
    process_chargebacks_result(result.body) if result.success?
  end 

  ################################################
  ########## AUS new file! #######################
  ################################################
  def self.account_updater_process_answers(gateway)
    answer = prepare_connection '/srv/api/ausStatus?', { :statusFilter => 'NEW' }
    0.upto(answer['statusCount'].to_i-1) do |i|
      request_file_by_id answer["rspfId_#{i}"], "rsp-"+answer["reqfId_#{i}"]+"-#{Time.now.to_i}.txt", gateway.club_id
    end
  end

  private
    def self.prepare_connection(path, options = {})
      conn = Faraday.new(:url => Settings.mes_aus_service.url, :ssl => {:verify => false})
      result = conn.get path, { 
        :userId => Settings.mes_aus_service.user, 
        :userPass => Settings.mes_aus_service.password, 
        :merchId => Settings.mes_aus_service.merchat_id 
      }.merge(options)
      answer = Rack::Utils.parse_nested_query(result.body)
    end

    def self.request_file_by_id(file_id, filename, club_id)
      answer = prepare_connection '/srv/api/ausDownload?', { :rspfId => file_id }
      if answer['rspCode'].to_i == 0
        full_filename = "#{Settings.mes_aus_service.folder}/#{filename}"
        file = File.open(full_filename, 'w')
        file.write answer
        file.close
        parse_file full_filename, club_id
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
        discretionary_data = line[92..123].strip

        member = Member.find_by_visible_id_and_club_id discretionary_data[1..32], club_id
        if member.nil?
          Rails.logger.info "Member id not found ##{discretionary_data} while parsing. #{line}"
        else
          member.aus_answered_at = Time.zone.now
          member.aus_status = response_code
          case response_code
          when 'NEWACCT'
            member.cc_number = new_account_number
            member.cc_year_exp = new_expiration_date[0..1].to_i+2000
            member.cc_month_exp = new_expiration_date[2..3]
          when 'NEWEXP'
            member.cc_year_exp = new_expiration_date[0..1].to_i+2000
            member.cc_month_exp = new_expiration_date[2..3]
          else
            Rails.logger.info "Member id ##{discretionary_data} with response #{response_code} ask for an action. #{line}"
          end
          member.save
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
        begin
          transaction_chargebacked = Transaction.find_by_payment_gateway_configuration_id_and_response_transaction_id gateway.id, args[:trident_transaction_id]
          member = Member.find_by_visible_id_and_club_id(args[:client_reference_number], gateway.club_id)
          if transaction_chargebacked.member_id == member.id
            member.chargeback! transaction_chargebacked, args
            member.save
          else
            raise "Chargeback ##{args[:control_number]} could not be processed. member and transaction_chargebacked are different! #{line}"
          end
        rescue Exception => e
          Airbrake.notify(:error_class => "MES::chargeback_report", :error_message => "#{e.to_s}\n\n#{$@[0..9] * "\n\t"}")
          Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
        end
      end
    end      

end