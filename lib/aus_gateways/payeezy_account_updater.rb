require 'gmail'
require 'net/sftp'
module PayeezyAccountUpdater

  ################################################
  ############ Process Chargeback
  ################################################
    
  def self.process_chargebacks
    PaymentGatewayConfiguration.where_active('payeezy').each do |gateway|
      PayeezyAccountUpdater.process_chargebacks_for_gateway gateway
    end
  end
  
  def self.process_chargebacks_for_gateway(gateway)
    client = Gmail.new(Settings.payeezy_report_service.gmail_account, Settings.payeezy_report_service.gmail_account_password)
    emails = client.inbox.emails(:unread, :from => "reports@businesstrack.com", subject: 'ONMC - Chargeback List')
    emails.each do |email|
      if email.attachments.any?
        local_filename = "tmp/#{email.attachments.first.filename}"
        File.open(local_filename,"wb"){|local| local << email.message.attachments.first.body.decoded}
        process_chargebacks_file(local_filename, gateway)
        File.delete(local_filename)
      end
      email.mark(:read)
    end
    client.logout
  end
  
  ################################################
  ############ Account Updater
  ################################################
  def self.account_updater_send_file_to_process
    PaymentGatewayConfiguration.where_active('payeezy').each do |gateway|
      PayeezyAccountUpdater.account_updater_send_file_to_process_for_gateway gateway
    end
  end
  
  def self.account_updater_process_response
    PaymentGatewayConfiguration.where_active('payeezy').each do |gateway|
      PayeezyAccountUpdater.account_updater_process_response_for_gateway gateway
    end
  end
  
  def self.account_updater_send_file_to_process_for_gateway(gateway)
    return if gateway.aus_login.nil? or gateway.aus_password.nil?
    local_filename = "#{Time.current.strftime("%Y%m%d")}_aus_request_#{gateway.club_id}.txt"
    generate_request_file(local_filename, gateway)
    send_request_files_to_payeezy(gateway)
  end
  
  def self.account_updater_process_response_for_gateway(gateway)
    return if gateway.aus_login.nil? or gateway.aus_password.nil?
    Net::SFTP.start(Settings.payeezy_aus_service.url, gateway.aus_login, {password: gateway.aus_password, port: 6522, keys:'~/.ssh/bam-key'}) do |sftp|
      sftp.dir.foreach("/available") do |entry|
        sftp.download!("/available/#{entry.name}", "#{Settings.payeezy_aus_service.folder}/#{entry.name}")
        process_aus_file "#{Settings.payeezy_aus_service.folder}/#{entry.name}", gateway.club_id
      end
    end
    send_email_with_contact_users(gateway.club_id)
  end
  
  private
    def self.process_chargebacks_file(chargeback_file, gateway)
      chargeback_data = CSV.read(chargeback_file, {col_sep: "\t", headers:true, encoding: 'UTF-16'})
      Rails.logger.info "[PayeezyChargebackReport-#{Date.yesterday.strftime('%m/%d/%Y')}] Processing file: #{chargeback_data.to_s}"
      chargeback_data.each do |data|
        begin
          user = User.find_by('id = ? OR email LIKE ?', data['Invoice Number'], "#{data['Invoice Number']}%")
          raise "Chargeback ##{data['Invoice Number']} could not be processed: Could not find user! #{data.to_s}" unless user
          sale_transaction_date     = data['Transaction Date'].to_date
          transactions_chargebacked  = user.transactions.where("payment_gateway_configuration_id = ? AND DATE(created_at) >= ? AND DATE(created_at) <=? AND last_digits = ? AND amount = ?", gateway.id, sale_transaction_date - 1.day, sale_transaction_date, data['Cardholder Number'][-4,4], data['Processed Transaction Amount'])
          raise "Chargeback ##{data['Invoice Number']} could not be processed: Could not find transaction! #{data.to_s}" unless transactions_chargebacked.first
          raise "Chargeback ##{data['Invoice Number']} could not be processed: Multiple possible sale transactions found." if transactions_chargebacked.count > 1

          user.chargeback! transactions_chargebacked.first, data, data['Chargeback Description']
        rescue Exception => e
          Auditory.report_issue("PAYEEZY::chargeback_report", $!, { :gateway_id => gateway.id.to_s, :data => data })
          Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
        end
      end
    end
    
    def self.process_aus_file(file_path, club_id)
      File.open(file_path).each_with_index do |line, index|
        next if line[0..1] != 'C1'
        current_token        = line[3..18]
        current_exp_date     = line[19..22]
        new_expiration_month = line[40..41].to_i
        new_expiration_year  = ('20' + line[42..43]).to_i
        response_code        = line[59..64]
        credit_card          = CreditCard.joins(:user).find_by(users: {club_id: club_id}, token: current_token)
        
        if credit_card.nil? 
          Rails.logger.error "CreditCard not found while parsing. File: #{file_path}. Line: #{index + 1}"
        else
          if credit_card.active?
            credit_card.update_attributes aus_answered_at: Time.current, aus_status: response_code
            case response_code
            when 'UPDATE'
              new_token       = line[24..39]
              new_last_digits = line[36..39]
              new_credit_card_type  = case line[58..58]
              when 'V'
                'visa'
              when 'M'
                'master'
              when 'D'
                'discovery'
              when 'A'
                'amex'
              else
                'unknown'
              end
              new_credit_card = CreditCard.new(token: new_token, 
                                               expire_year: new_expiration_year, 
                                               expire_month: new_expiration_month, 
                                               cc_type: new_credit_card_type, 
                                               last_digits: new_last_digits)
              answer = credit_card.user.add_new_credit_card(new_credit_card)
              if answer[:code] == Settings.error_codes.success
                Auditory.audit(nil, credit_card, "Credit card #{credit_card.last_digits} AUS updated to #{new_last_digits}", credit_card.user, Settings.operation_types.aus_update_credit_card)
              else
                Auditory.report_issue("Payeezy::aus_update_process #{response_code}", nil, { :credit_card => credit_card.id, :answer => answer, :file => file_path, line: index+1 })
              end
            when 'EXPIRY'
              new_expire_year   = new_expiration_year
              new_expire_month  = new_expiration_month
              Auditory.audit(nil, credit_card, "AUS expiration update from #{credit_card.expire_month}/#{credit_card.expire_year} to #{new_expire_month}/#{new_expire_year}", credit_card.user, Settings.operation_types.aus_recycle_credit_card)
              credit_card.update_attributes expire_year: new_expire_year, expire_month: new_expire_month
            when 'CONTAC'
              # do nothing. User will enter in SD cicle upon billing. 
            else
              Auditory.report_issue("Payeezy::aus_update_process : Unexpected response code: #{response_code}.", nil, { :file => file_path, line: index+1 })
            end
          end
        end
      end
    rescue
      Auditory.report_issue("PAYEEZY::process_aus_file", $!, { file_path: file_path })
    end
    
    def self.generate_request_file(filename, gateway)
      # users with expired credit card and active
      users     = User.joins(:credit_cards).billable.where([ 'date(bill_date) = ? AND club_id = ? AND active = 1 AND gateway = ? AND cc_type != ?', (Time.current + 1.week).to_date, gateway.club_id, gateway.gateway, 'american_express' ])
      if users.any?
        file_path     = File.join(Settings.payeezy_aus_service.unsent_folder, filename)
        file          = File.open(file_path, 'wb')
        filler        = ' '
        count         = 5
        # add header
        file.write ['00', Settings.payeezy_aus_service.merchant_name.ljust(25, ' '), 
                    Settings.payeezy_aus_service.merchant_number.ljust(15, ' '), 
                    Time.current.strftime('%m%d'), filler * 18 , "T N    CAU1"].join(' ') + "\n"
        # add Visa Card Type Information Record (visa_acquirer_bin, bank_name)
        file.write ['01V', filler * 14, Settings.payeezy_aus_service.visa_acquirer_bin, filler * 8, 
                    Settings.payeezy_aus_service.bank_name, filler * 29].join(' ') + "\n"
        # add Master Card Type Information Record
        file.write ['01M', filler * 14, Settings.payeezy_aus_service.master_card_ica, filler * 8,  
                    Settings.payeezy_aus_service.bank_name, filler * 29].join(' ') + "\n"

        # add Records for each user
        users.each do |user|
          credit_card = user.active_credit_card
          expire_date = '%02i' % credit_card.expire_month + credit_card.expire_year.to_s[2..3]
          file.write ["C1T", credit_card.token, expire_date, filler * 57].join() + "\n"
          credit_card.aus_sent_at = Time.zone.now
          credit_card.save
          count += 1
        end
          
        # adding summary (merchant_name, merchant_number, token_type)
        file.write ['70', Settings.payeezy_aus_service.merchant_name.ljust(25, ' '),
                    Settings.payeezy_aus_service.merchant_number, filler * 12, 'VM28', 
                    filler * 20].join(' ') + "\n"
        
        # adding file tracking
        file.write ['80', Settings.payeezy_aus_service.merchant_name.ljust(25, ' '), 
                    Settings.payeezy_aus_service.merchant_number, filler * 2, ("%09i" % count), 
                    filler * 25].join(' ') + "\n"
        file.close
        true
      else
        false
      end
    rescue
      Auditory.report_issue("PAYEEZY::generate_aus_request_file", $!, { :gateway_id => gateway.id.to_s, filename: filename })
      false
    end

    def self.send_request_files_to_payeezy(gateway)
      file_name = ''
      Dir[File.join(Settings.payeezy_aus_service.unsent_folder, '*.txt')].each do |source_file|
        file_name = File.basename(source_file)
        Net::SFTP.start(Settings.payeezy_aus_service.url, gateway.aus_login, password: gateway.aus_password, port: 6522, keys: '~/.ssh/bam-key') do |sftp|
          sftp.upload!(source_file, 'RCDMONCU.' + file_name)
        end
        # If no error, we assume that the file was uploaded and move it to the sent/ folder
        File.rename source_file, File.join(Settings.payeezy_aus_service.sent_folder, file_name)
      end
    rescue
      Auditory.report_issue('PAYEEZY::aus_send_request_file', $ERROR_INFO, gateway_id: gateway.id.to_s, local_filename: file_name)
    end
    
    def self.send_email_with_contact_users(club_id)
      contact_email_list = Club.find(club_id).payment_gateway_errors_email
      return unless contact_email_list.present?
      credit_cards = CreditCard.joins(:user).where(users: {club_id: club_id}, aus_status: 'CONTAC', aus_answered_at: Time.current.beginning_of_day..Time.current.end_of_day)
      if credit_cards.size > 0
        csv = "id,first_name,last_name,email,phone,status,cs_next_bill_date\n"
        csv += credit_cards.collect {|cc| [ cc.user_id, cc.user.first_name, cc.user.last_name, cc.user.email, cc.user.full_phone_number, cc.user.status, cc.user.next_retry_bill_date ].join(',') }.join("\n")
        Notifier.call_these_users(csv, contact_email_list).deliver_later!
      end
    rescue
      Auditory.report_issue("PAYEEZY::send_email_with_contact_users", $!, {club_id: club_id})
    end
end
