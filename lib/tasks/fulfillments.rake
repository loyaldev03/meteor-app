namespace :fulfillments do  
  desc "Create fulfillment report for Brian Miller."
  task :generate_fulfillment_naamma_report => :environment do
    begin
      Rails.logger = Logger.new("#{Rails.root}/log/fulfillment_naamma_report.log")
      Rails.logger.level = Logger::DEBUG
      ActiveRecord::Base.logger = Rails.logger
      Rails.logger.info " *** [#{I18n.l(Time.zone.now, :format =>:dashed)}] Starting rake task"

      tall = Time.zone.now

      fulfillment_file = FulfillmentFile.new 
      fulfillment_file.agent = Agent.find_by_email('batch@xagax.com')

      if Rails.env=='prototype'
        fulfillment_file.club = Club.find 41
      elsif Rails.env=='production'
        fulfillment_file.club = Club.find 4
      elsif Rails.env=='staging'
        fulfillment_file.club = Club.find 17
      end

      Time.zone = fulfillment_file.club.time_zone
      fulfillment_file.initial_date = Time.zone.now-7.days
      fulfillment_file.end_date = Time.zone.now
      fulfillment_file.product = "KIT-CARD"
      fulfillment_file.save!

      fulfillments = Fulfillment.includes(:member).where( 
        ["members.club_id = ? AND fulfillments.assigned_at BETWEEN ? 
          AND ? and fulfillments.status = 'not_processed' 
          AND fulfillments.product_sku like 'KIT-CARD'", fulfillment_file.club_id, 
          fulfillment_file.initial_date, fulfillment_file.end_date ])
      fulfillment_file.save!
      package = Axlsx::Package.new                  

      Rails.logger.info " *** Processing #{fulfillments.count} fulfillments for club #{fulfillment_file.club_id}"
      package.workbook.add_worksheet(:name => "Fulfillments") do |sheet|
        sheet.add_row [ 'First Name', 'Last Name', 'Member Number', 'Membership Type (fan/subscriber)', 
                       'Address', 'City', 'State', 'Zip','Phone number', 'Join date', 'Membership expiration date', 'email' ]
        unless fulfillments.empty?
          fulfillments.each do |fulfillment|
            tz = Time.zone.now
            Rails.logger.info " *** Processing #{fulfillment.id} for member #{fulfillment.member_id}"
            member = fulfillment.member
            membership = member.current_membership
            row = [ member.first_name, member.last_name, member.id, 
                    membership.terms_of_membership.name, member.address, 
                    member.city, member.state, "=\"#{member.zip}\"", member.full_phone_number,
                    sanitize_date(member.join_date, :only_date_short), 
                    sanitize_date(membership.cancel_date, :only_date_short),
                    member.email
                  ]
            sheet.add_row row 
            fulfillment_file.fulfillments << fulfillment
            Rails.logger.info " *** It took #{Time.zone.now - tz} to process #{fulfillment.id} for member #{fulfillment.member_id}"
          end
        end
      end

      temp = Tempfile.new("naamma_kit-card_report.xlsx") 
      
      package.serialize temp.path
      Notifier.fulfillment_naamma_report(temp, fulfillment_file.fulfillments.count).deliver!
      
      temp.close 
      temp.unlink

      fulfillment_file.mark_fulfillments_as_in_process
      fulfillment_file.processed
    
    rescue Exception => e
      Auditory.report_issue("Fulfillments::NaammaReport", e, {:backtrace => "#{$@[0..9] * "\n\t"}"})
      Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
    ensure
      Rails.logger.info "It all took #{Time.zone.now - tall} to run task"
    end
  end


  desc "Create fulfillment report for sloops products reated to Naamma."
  task :generate_sloop_naamma_report => :environment do
    begin 
      require 'csv'
      require 'net/ftp'

      Rails.logger = Logger.new("#{Rails.root}/log/sloop_naamma_report.log")
      Rails.logger.level = Logger::DEBUG
      ActiveRecord::Base.logger = Rails.logger
      tall = Time.zone.now
      Rails.logger.info " *** [#{I18n.l(Time.zone.now, :format =>:dashed)}] Starting rake task"

      fulfillment_file = FulfillmentFile.new 
      fulfillment_file.agent = Agent.find_by_email('batch@xagax.com')

      if Rails.env=='prototype'
        fulfillment_file.club = Club.find 41
      elsif Rails.env=='production'
        fulfillment_file.club = Club.find 4
      elsif Rails.env=='staging'
        fulfillment_file.club = Club.find 17
      end
      
      Time.zone = fulfillment_file.club.time_zone
      fulfillment_file.initial_date = Time.zone.now-7.days
      fulfillment_file.end_date = Time.zone.now
      fulfillment_file.product = "SLOOPS"

      fulfillments = Fulfillment.includes(:member).where( 
        ["members.club_id = ? AND fulfillments.assigned_at BETWEEN ? 
          AND ? and fulfillments.status = 'not_processed' 
          AND fulfillments.product_sku != 'KIT-CARD'", fulfillment_file.club_id, 
          fulfillment_file.initial_date, fulfillment_file.end_date ])
      temp_file = "#{I18n.l(Time.zone.now, :format => :only_date)}_sloop_naamma.csv"

      Rails.logger.info " *** Processing #{fulfillments.count} fulfillments for club #{fulfillment_file.club_id}"
      CSV.open( temp_file, "w" ) do |csv|
        csv << [ 'First Name', 'Last Name', 'Product Choice', 'address', 'city', 'state', 'zip', 'join date', 'phone number', 'Email', 'TOM ID', 'TOM Name', 'TOM Description' ]
        unless fulfillments.empty?
          fulfillments.each do |fulfillment|
            tz = Time.zone.now
            Rails.logger.info " *** Processing #{fulfillment.id} for member #{fulfillment.member_id}"       
            member = fulfillment.member
            membership = member.current_membership
            tom = TermsOfMembership.find(membership.terms_of_membership_id)            
            csv << [member.first_name, member.last_name, fulfillment.product_sku, member.address, 
                    member.city, member.state, "#{member.zip}"  ,
                    sanitize_date(member.join_date, :only_date_short), 
                    member.full_phone_number, member.email,
                    tom.id, tom.name, tom.description]
            fulfillment_file.fulfillments << fulfillment
            Rails.logger.info " *** It took #{Time.zone.now - tz} to process #{fulfillment.id} for member #{fulfillment.member_id}"
          end
        end
      end
      fulfillment_file.save!
      
      begin
        ftp = Net::FTP.new('ftp.stoneacreinc.com')
        ftp.login(user = "phoenix", passwd = "ph03n1xFTPu$3r")
        folder = fulfillment_file.club.name
        begin
          ftp.mkdir(folder)
          ftp.chdir(folder)
        rescue Net::FTPPermError
          ftp.chdir(folder)
        end
        ftp.putbinaryfile(temp_file, File.basename(temp_file))
        fulfillment_file.mark_fulfillments_as_in_process
        fulfillment_file.processed
      rescue Exception => e
        Auditory.report_issue('NaammaSloopReport:create', e, { :fulfillment_file => fulfillment_file.inspect })
      ensure
        ftp.quit()
      end

      File.delete(temp_file)
    rescue Exception => e
      Auditory.report_issue("Fulfillments::NaammaSloopReport", e, {:backtrace => "#{$@[0..9] * "\n\t"}"})
      Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
    ensure
      Rails.logger.info "It all took #{Time.zone.now - tall} to run task"    
    end
  end


  desc "Create fulfillment report for kit-card products reated to NFLA. We search for sloops fulfillments instead of kit-card, since NFLA uses sloops."
  task :generate_nfla_report => :environment do
    begin
      require 'csv'
      Rails.logger = Logger.new("#{Rails.root}/log/nfla_report.log")
      Rails.logger.level = Logger::DEBUG
      ActiveRecord::Base.logger = Rails.logger
      tall = Time.zone.now
      Rails.logger.info " *** [#{I18n.l(Time.zone.now, :format =>:dashed)}] Starting rake task"

      fulfillment_file = FulfillmentFile.new 
      fulfillment_file.agent = Agent.find_by_email('batch@xagax.com')

      if Rails.env=='prototype'
        fulfillment_file.club = Club.find 2
      elsif Rails.env=='production'
        fulfillment_file.club = Club.find 6
      elsif Rails.env=='staging'
        fulfillment_file.club = Club.find 19
      end

      Time.zone = fulfillment_file.club.time_zone
      fulfillment_file.initial_date = Time.zone.now-7.days
      fulfillment_file.end_date = Time.zone.now
      fulfillment_file.product = "SLOOPS"
      fulfillment_file.save!

      package = Axlsx::Package.new

      fulfillments = Fulfillment.includes(:member => :memberships).where( 
          ["members.club_id = ? 
            AND memberships.status != 'lapsed' 
            AND fulfillments.assigned_at BETWEEN ? AND ? 
            AND fulfillments.status = 'not_processed' 
            AND fulfillments.product_sku != 'KIT-CARD'", 
            fulfillment_file.club_id, 
            fulfillment_file.initial_date, 
            fulfillment_file.end_date
          ]
      )

      toms = TermsOfMembership.where(:club_id => fulfillment_file.club)
      toms.each do |tom|
        Rails.logger.info " *** Processing #{fulfillments.count} fulfillments for club #{fulfillment_file.club_id}"
        package.workbook.add_worksheet(:name => tom.name) do |sheet|
          sheet.add_row [ 'Code', 
                          'First Name', 
                          'Last Name', 
                          'Member Valid Thru', 
                          'Member Since', 
                          'Membership Category', 
                          'Type of Membership', 
                          'Account',
                          'Street1', 'Street2', 'City', 'State', 'Zip',
                          'Product Name', 'Product SKU' ]
          fulfillments.each do |fulfillment|
            tz = Time.zone.now
            Rails.logger.info " *** Processing #{fulfillment.id} for member #{fulfillment.member_id}"
            member = fulfillment.member
            membership = member.current_membership
            if membership.terms_of_membership_id == tom.id 
              row = [ member.id.to_s, 
                      member.first_name, 
                      member.last_name,
                      sanitize_date(member.next_retry_bill_date, :only_date_short),
                      sanitize_date(member.member_since_date, :only_date_short), 
                      nfla_get_tom_category(membership.terms_of_membership.id),
                      membership.terms_of_membership.name,
                      member.last_name + ' ' + member.first_name,
                      member.address, '', member.city, member.state, member.zip,
                      fulfillment.product.name, fulfillment.product_sku ]
              sheet.add_row row 
              fulfillment_file.fulfillments << fulfillment
            end
            Rails.logger.info " *** It took #{Time.zone.now - tz} to process #{fulfillment.id} for member #{fulfillment.member_id}"
          end
        end
      end

      temp = Tempfile.new("nfla_kit-card_report.xlsx") 
      
      package.serialize temp.path
      Notifier.fulfillment_nfla_report(temp, fulfillment_file.fulfillments.count).deliver!
      
      temp.close 
      temp.unlink

      fulfillment_file.mark_fulfillments_as_in_process
      fulfillment_file.processed

    rescue Exception => e
      Auditory.report_issue("Fulfillments::NflaReport", e, {:backtrace => "#{$@[0..9] * "\n\t"}"})
      Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
    ensure
      Rails.logger.info "It all took #{Time.zone.now - tall} to run task"        
    end  
  end

  def nfla_get_tom_category(tom_id)
    if Rails.env == 'prototype'
      if [111, 113, 115].include? tom_id.to_i
        'Professional'
      elsif [116, 117, 112].include? tom_id.to_i
        'Associate'
      else
        ''
      end
    elsif Rails.env == 'production'
      # NFLA TOM Ids
      # Annual Player $100 = 47
      # Annual Spouse $50 = 48
      # Lifetime $3500 = 49
      # Complimentary Account = 50
      # Annual Associate $150 = 51
      # Annual Professional $100 = 52
      # HOF Complimentary Account = 53
      if [47, 49, 53].include? tom_id.to_i
        'Professional'
      elsif [48, 50, 51, 52].include? tom_id.to_i
        'Associate'
      else
        ''
      end
    else
      ''
    end
  end
  
  def sanitize_date(date, format)
    allowed_dt_formats = ["ActiveSupport::TimeWithZone", "Date", "DateTime"]

    if allowed_dt_formats.include? date.class.to_s
      return I18n.l(date, :format => format)
    else
      return ""
    end
  end

  desc "Magazine cancellation file generation for hot rod"
  task :send_magazine_cancellation => :environment do
    begin
      require 'csv'
      Rails.logger = Logger.new("#{Rails.root}/log/send_magazine_cancellation.log")
      Rails.logger.level = Logger::DEBUG
      ActiveRecord::Base.logger = Rails.logger
      tall = Time.zone.now
      Rails.logger.info " *** [#{I18n.l(Time.zone.now, :format =>:dashed)}] Starting rake task"

      if Rails.env=='prototype'
        club = Club.find 48
      elsif Rails.env=='production'
        club = Club.find 6
      elsif Rails.env=='staging'
        club = Club.find 19
      end
        club = Club.find 2
      Time.zone = club.time_zone
      initial_date = Time.zone.now - 7.days
      end_date = Time.zone.now 
      members = Member.joins(:memberships).where(["members.club_id = ? AND memberships.status = 'lapsed' AND
        cancel_date BETWEEN ? and ? ", club.id, initial_date, end_date])

      package = Axlsx::Package.new
      package.workbook.add_worksheet(:name => tom.name) do |sheet|
      package.workbook.add_worksheet(:name => "Cancelation Magazine") do |sheet|
        sheet.add_row ["RecType", "FHID", "PubCode", "Email", "CustomerCode", "CheckDigit", 
          "Keyline", "ISSN", "FirstName", "LastName", "JobTitle", "Company", "Address", "SupAddress", 
          "City", "State", "Zip", "Country", "CountryCode", "BusPhone", "HomePhone", "FaxPhone", 
          "ZFTerm", "AgentID", "AuditCode", "VersionCode", "PromoCode", "StartIssue", "EndIssue", 
          "Term", "CurrencyCode", "GrossPrice", "NetPrice", "IssuesRemaining", "OrderNumber", 
          "AutoRenew", "UMC", "Premium", "PayStatus","SubType", "TimesRenewed", "FutureUse"]
        member.each do |member|
          row = [ '', '', '', member.email, member.email, '', '', '', member.first_name, member.last_name, '', '',
                member.address, '', member.city, member.state, member.zip, member.country, '', '', '', '', '-8',
                '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'cancel', '', '', '' ]


          seet.add_row row
        end
      end
    end
  end
end