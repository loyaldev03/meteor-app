namespace :fulfillments do  
  desc "NO LONGER USED (https://www.pivotaltracker.com/story/show/76527736) - Create fulfillment report for Brian Miller."
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

      fulfillments = Fulfillment.includes(:user).where( 
        ["users.club_id = ? AND fulfillments.assigned_at BETWEEN ? 
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
            Rails.logger.info " *** Processing #{fulfillment.id} for member #{fulfillment.user_id}"
            member = fulfillment.user
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
            Rails.logger.info " *** It took #{Time.zone.now - tz}seconds to process #{fulfillment.id} for member #{fulfillment.user_id}"
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
      Rails.logger.info "It all took #{Time.zone.now - tall}seconds to run task"
    end
  end


  desc "NO LONGER USED (https://www.pivotaltracker.com/story/show/76527736) - Create fulfillment report for sloops products reated to Naamma."
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

      fulfillments = Fulfillment.includes(:user).where( 
        ["users.club_id = ? AND fulfillments.assigned_at BETWEEN ? 
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
            Rails.logger.info " *** Processing #{fulfillment.id} for member #{fulfillment.user_id}"       
            member = fulfillment.user
            membership = member.current_membership
            tom = TermsOfMembership.find(membership.terms_of_membership_id)            
            csv << [member.first_name, member.last_name, fulfillment.product_sku, member.address, 
                    member.city, member.state, "#{member.zip}"  ,
                    sanitize_date(member.join_date, :only_date_short), 
                    member.full_phone_number, member.email,
                    tom.id, tom.name, tom.description]
            fulfillment_file.fulfillments << fulfillment
            Rails.logger.info " *** It took #{Time.zone.now - tz}seconds to process #{fulfillment.id} for member #{fulfillment.user_id}"
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
      Rails.logger.info "It all took #{Time.zone.now - tall}seconds to run task"    
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

      fulfillments = Fulfillment.includes(:user => :memberships).where( 
          ["users.club_id = ? 
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
            Rails.logger.info " *** Processing #{fulfillment.id} for member #{fulfillment.user_id}"
            member = fulfillment.user
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
            Rails.logger.info " *** It took #{Time.zone.now - tz}seconds to process #{fulfillment.id} for member #{fulfillment.user_id}"
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
      Rails.logger.info "It all took #{Time.zone.now - tall}seconds to run task"        
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

  desc "NO LONGER USED (https://www.pivotaltracker.com/story/show/104026972) - Create magazine fulfillment file for Hot Rod" 
  task :send_print_magazine_hot_rod_file => :environment do
    require 'csv'
    require 'net/ftp'    
    Rails.logger = Logger.new("#{Rails.root}/log/send_print_magazine_hot_rod_file.log")
    Rails.logger.level = Logger::DEBUG
    ActiveRecord::Base.logger = Rails.logger

    fulfillment_file = FulfillmentFile.new 
    fulfillment_file.agent = Agent.find_by_email('batch@xagax.com')

    if Rails.env=='prototype'
      fulfillment_file.club = Club.find 48
    elsif Rails.env=='production'
      fulfillment_file.club = Club.find 9
    elsif Rails.env=='staging'
      fulfillment_file.club = Club.find 21
    end

    Time.zone = fulfillment_file.club.time_zone
    Rails.logger.info " *** [#{I18n.l(Time.zone.now, :format =>:dashed)}] Starting rake task"
    tall = Time.zone.now
    fulfillment_file.initial_date = Time.zone.now-7.days
    fulfillment_file.end_date = Time.zone.now
    fulfillment_file.product = "HOTRODPRINTMAGAZINE"
    fulfillment_file.save!
    file_info = ""

    # NEW JOIN and REINSTATEMENT
    fulfillments = Fulfillment.joins(:user).readonly(false).where(["users.club_id = ? AND product_sku = ?
      AND fulfillments.status = 'not_processed'", fulfillment_file.club_id, fulfillment_file.product]).group("users.id") 
    fulfillments.each do |fulfillment| 
      begin
        member = fulfillment.user
        membership_billing_transaction = member.transactions.where(["operation_type = 101 AND 
          membership_id = ? AND created_at BETWEEN ? AND ?", 
          member.current_membership_id, fulfillment_file.initial_date, fulfillment_file.end_date]).last
        if membership_billing_transaction
          if member.operations.where(["operation_type = ?", Settings.operation_types.recovery]).empty?
            file_info << process_fulfillment(fulfillment, fulfillment_file, "1")
          else
            file_info << process_fulfillment(fulfillment, fulfillment_file, "5")
          end
        end
      rescue Exception => e
        Auditory.report_issue("Fulfillments:HotRodPrintMagazine", e, {:backtrace => "#{$@[0..9] * "\n\t"}"})
        Rails.logger.info "    [!] failed: NEW JOIN or REINSTATEMENT #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
      end
    end
    # RENEWAL
    fulfillments = Fulfillment.joins(:user).readonly(false).where(["users.club_id = ? AND fulfillments.renewable_at BETWEEN ? and ?",
     fulfillment_file.club_id, fulfillment_file.initial_date, fulfillment_file.end_date])
    fulfillments.each do |fulfillment|
      begin
        if fulfillment.sent?
          if fulfillment.renewed
            file_info << process_fulfillment(fulfillment, fulfillment_file, "2")
          else
            fulfillment.update_attribute :renewable_at, fulfillment.user.next_retry_bill_date+1.day
          end
        end
      rescue Exception => e
        Auditory.report_issue("Fulfillments:HotRodPrintMagazine", e, {:backtrace => "#{$@[0..9] * "\n\t"}"})
        Rails.logger.info "    [!] failed: RENEWAL #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
      end
    end
    # CANCEL
    memberships = Membership.joins(:terms_of_membership).where(["terms_of_memberships.club_id = ? AND
      memberships.cancel_date BETWEEN ? and ?", fulfillment_file.club_id, fulfillment_file.initial_date, 
      fulfillment_file.end_date]).group("memberships.id") 
    memberships.each do |membership| 
      begin
        member = membership.user 
        if member.lapsed?
          fulfillment = member.fulfillments.where("product_sku = ? and status = 'sent' and created_at >= ?", fulfillment_file.product, member.join_date).last
          if fulfillment
            file_info << process_fulfillment(fulfillment, fulfillment_file, "3")
          end
        end
      rescue Exception => e
        Auditory.report_issue("Fulfillments:HotRodPrintMagazine", e, {:backtrace => "#{$@[0..9] * "\n\t"}"})
        Rails.logger.info "    [!] failed: CANCEl #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
      end
    end
    # CHANGED ADDRESS 
    members = User.joins(:operations).where(["users.club_id = ? AND operations.operation_type = ? AND 
      operations.created_at BETWEEN ? and ?", fulfillment_file.club_id, Settings.operation_types.profile_updated,
      fulfillment_file.initial_date, fulfillment_file.end_date]).group("users.id")
    members.each do |member|
      begin
        fulfillment = member.fulfillments.where("product_sku = ? and status = 'sent'", fulfillment_file.product).last
        if fulfillment
          profile_edit_operations = member.operations.where(["operation_type = ? AND notes is not null AND 
            created_at BETWEEN ? and ?", Settings.operation_types.profile_updated, fulfillment_file.initial_date, 
            fulfillment_file.end_date])
          if check_address_changed(profile_edit_operations)
            file_info << process_fulfillment(fulfillment, fulfillment_file, "4")
          end
        end
      rescue Exception => e
        Auditory.report_issue("Fulfillments:HotRodPrintMagazine", e, {:backtrace => "#{$@[0..9] * "\n\t"}"})
        Rails.logger.info "    [!] failed: CHANGED ADDRESS #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
      end
    end

    fulfillment_file.save
    temp_file = File.new("#{I18n.l(Time.zone.now, :format => :only_date)}_magazine_hot_rod.txt", 'w')
    temp_file.write(file_info)
    temp_file.close
    
    begin
      ftp = Net::FTP.new('ftp.palmcoastd.com')
      ftp.login(user = "agy700-hotrodclub", passwd = "3lP585sv")
      ftp.putbinaryfile(temp_file, File.basename(temp_file))
      fulfillment_file.fulfillments.where_not_processed.each{ |x| x.update_status(fulfillment_file.agent, 'in_process', 'Fulfillment file generated', fulfillment_file.id)}
      fulfillment_file.processed   
    rescue Exception => e
      Auditory.report_issue('HotRodPrintMagazine:create', e, { :fulfillment_file => fulfillment_file.inspect })
    ensure
      ftp.quit()
      File.delete(temp_file)
    end 
    Rails.logger.info "It all took #{Time.zone.now - tall}seconds to run task"
  end

  def process_fulfillment(fulfillment, fulfillment_file, record_type)
    tz = Time.zone.now
    Rails.logger.info " *** Processing #{fulfillment.id} for member #{fulfillment.user_id}"
    line = ""
    @member = fulfillment.user
    @membership = @member.current_membership
    line << record_type # RECORD TYPE
    line << (record_type=="4" ? "2" : "1") # RECORD CODE
    line << "".rjust(4, '5HRC') # AGENT ID NUMBER 
    line << "".rjust(13, ' ') # FILLER
    line << "00670".rjust(5, '0') # UNIVERSAL MAGAZINE CODE
    line << ((@membership.terms_of_membership.installment_period/30.416667).round.to_s).rjust(3, '0') # TERM
    line << "1".rjust(5,'0') # COPY SUB (BULK)
    line << "".rjust(7,'0') # GROSS AMOUNT
    line << "".rjust(7,'0') # NET/REMIT AMOUNT
    line << "1" # ABC CODE
    line << "".rjust(1, ' ') # RENEWAL PROMOTION CODE  - NO LONGER USED
    line << "".rjust(1, ' ') # FILLER
    line << "".rjust(1, ' ') # PREMIUM NUMBER 1
    line << "".rjust(1, ' ') # PREMIUM NUMBER 2
    line << "".rjust(11, ' ') # Trans ID
    line << "".rjust(7, ' ') # FILLER
    line << Time.zone.now.to_date.strftime("%Y%m%d").to_s.rjust(8, '0') # CLEARING DATE
    line << get_reinstate_or_cancel_date(record_type).to_date.strftime("%Y%m%d").rjust(8, '0') # REINSTATE / CANCEL DATE
    line << "".rjust(3, ' ') # ISSUES TO GO
    line << record_type=="3" ? check_for_refund_upon_cancel : " " # PAID / UNPAID
    line << "".rjust(3, ' ') # ISSUES PAID
    line << "".rjust(7, ' ') # ISSUES PAID DOLLARS
    line << @member.full_name.truncate(27, omission:"").ljust(27,' ') # NAME
    line << "".rjust(3, ' ') # FILLER
    line << @member.full_address.truncate(27, omission:"").ljust(27,' ') # ADDRESS
    line << "".rjust(3, ' ') # FILLER
    line << "".rjust(27, ' ') # SUPPLEMENT (IF NECESSARY)
    line << "".rjust(3, ' ') # FILLER
    line << "".ljust(30, ' ') # COMPANY NAME
    line << @member.city.ljust(15, ' ') # CITY
    line << @member.state.ljust(2, ' ') # STATE
    line << @member.country.ljust(3, ' ') # COUNTRY CODE
    line << @member.zip.ljust(9, ' ') # ZIP / CANADA
    line << "".rjust(15, ' ') # FOREIGN REGION
    line << "".rjust(1, ' ') # ID NUMBER 1 INDICATOR
    line << "".rjust(15, ' ') # ID NUMBER 1
    line << "".rjust(1, ' ') # ID NUMBER 2 INDICATOR
    line << "".rjust(15, ' ') # ID NUMBER 2
    line << "".rjust(1, ' ') # ID NUMBER 3 INDICATOR
    line << "".rjust(15, ' ') # ID NUMBER 3
    line << "".rjust(1, ' ') # ID NUMBER 4 INDICATOR
    line << "".rjust(15, ' ') # ID NUMBER 4
    line << "".rjust(1, ' ') # ID NUMBER 5 INDICATOR
    line << "".rjust(15, ' ') # ID NUMBER 5
    line << "".rjust(9, ' ') # FILLER
    line << "".rjust(1, ' ') # SPECIAL ID
    line << "".rjust(24, ' ') # FILLER
    line << "".rjust(3, ' ') # VERIFIED LOCATION
    line << "".rjust(1, ' ') # CASH / PAID DURING SRVC
    line << "".rjust(18, ' ') # FILLER
    line << "".rjust(4, ' ') # PREFERRED START
    line << "".rjust(44, ' ') # FILLER / FUTURE USE
    line << "".rjust(1, ' ') # FILLER
    line << "".ljust(75, ' ') # Subscriber E-MAIL ADDRESS 1
    line << "".rjust(1, ' ') # NO LONGER ACTIVE
    line << "".rjust(1, ' ') # FILLER
    line << "".rjust(75, ' ') # FILLER
    line << "".rjust(1, ' ') # NO LONGER ACTIVE
    line << (@member.type_of_phone_number=="home" ? @member.full_phone_number : "").rjust(15, '0') # HOME PHONE NUMBER
    line << "".rjust(15, '0') # HOME FAX NUMBER
    line << (@member.type_of_phone_number!="home" ? @member.full_phone_number : "").rjust(15, '0') # BUSINESS PHONE NUMBER
    line << "".rjust(15, '0') # BUSINESS FAX NUMBER
    line << "".rjust(20, '0') # FILLER
    line << "".rjust(1, '0')  # RENEWAL TEST CODE - NO LONGER USED
    line << "X".rjust(1, '0')  # HOME PHONE OPTOUT
    line << "X".rjust(1, '0')  # 3RD PARTY OPTOUT
    line << "X".rjust(1, '0')  # OFFICE OPTOUT
    line << "X".rjust(1, '0')  # 3RD PARTY OFF. OPTOUT
    line << "X".rjust(1, '0')  # HOME FAX OPTOUT
    line << "X".rjust(1, '0')  # 3RD HOME FAX OPTOUT
    line << "X".rjust(1, '0')  # OFFICE FAX OPTOUT
    line << "X".rjust(1, '0')  # 3RD OFFICE FAX OPTOUT
    line << "X".rjust(1, '0')  # EMAIL SUBSCRIPTION OPTOUT
    line << "X".rjust(1, '0')  # EMAIL PUBLISHER OPTOUT
    line << "X".rjust(1, '0')  # EMAIL 3RD PARTY OPTOUT
    line << "X".rjust(1, '0')  # Recip EMAIL SUBSCRIPTION OPTOUT
    line << "X".rjust(1, '0')  # Recip EMAIL PUBLISHER OPTOUT
    line << "X".rjust(1, '0')  # Recip EMAIL 3RD PARTY OPTOUT
    line << "P".rjust(1, '0')  # MARKETING 20
    line << "\n".rjust(1, '0')
    fulfillment_file.fulfillments << fulfillment
    Rails.logger.info " *** It took #{Time.zone.now - tz}seconds to process #{fulfillment.id} for member #{fulfillment.user_id}"
    line
  end

  def check_address_changed(profile_edit_operations)
    changed = false
    profile_edit_operations.each do |operation|
      unless changed
        ["address", "state,", "city", "zip", "country"].each do |word|
          return true  if operation.notes.include? word
        end
      end
    end
    changed
  end

  def get_reinstate_or_cancel_date(record_type)
    if record_type == "3"
      @member.cancel_date
    else
      @member.transactions.where("membership_id = ? and operation_type = ?", 
                                @member.current_membership_id, Settings.operation_types.membership_billing).
                                order("created_at DESC").first.created_at
    end
  end

  def check_for_refund_upon_cancel
    operations_refund = @member.operations.where("operation_type = ? and created_at between ? and ?", 
                          @member.id, Settings.operation_types.credit, @member.cancel_date-1.day, @member.cancel_date+1.day )
    if operations_refund.empty?
      "P"
    else
      "U"
    end
  end
end