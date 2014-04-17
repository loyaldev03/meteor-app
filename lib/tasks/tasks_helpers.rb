module TasksHelpers
  #######################################################
  ################ MEMBER ###############################
  #######################################################

  # Method used from rake task and also from tests!
  def self.bill_all_members_up_today
    file = File.open("/tmp/bill_all_members_up_today_#{Rails.env}.lock", File::RDWR|File::CREAT, 0644)
    file.flock(File::LOCK_EX)

    base = Member.includes(:current_membership => :terms_of_membership).where("DATE(next_retry_bill_date) <= ? AND members.club_id IN (select id from clubs where billing_enable = true) AND members.status NOT IN ('applied','lapsed') AND manual_payment = false AND terms_of_memberships.is_payment_expected = 1", Time.zone.now.to_date).limit(4000)

    Rails.logger.info " *** [#{I18n.l(Time.zone.now, :format =>:dashed)}] Starting members:billing rake task, processing #{base.count} members"
    base.to_enum.with_index.each do |member,index| 
      tz = Time.zone.now
      begin
        Rails.logger.info "  *[#{index+1}] processing member ##{member.id} nbd: #{member.next_retry_bill_date}"
        member.bill_membership
      rescue Exception => e
        Auditory.report_issue("Billing::Today", "#{e.to_s}\n\n#{$@[0..9] * "\n\t"}", { :member => member.inspect, :credit_card => member.active_credit_card.inspect })
        Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
      end
      Rails.logger.info "    ... took #{Time.zone.now - tz}seconds for member ##{member.id}"
    end
    file.flock(File::LOCK_UN)
  rescue Exception => e
    Auditory.report_issue("Billing::Today", e, {:backtrace => "#{$@[0..9] * "\n\t"}"})
    Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
  end

  def self.refresh_autologin
    index = 0
    Member.find_each do |member|
      begin
        index = index+1
        Rails.logger.info "   *[#{index}] processing member ##{member.id}"
        member.refresh_autologin_url!
      rescue
        Auditory.report_issue("Members::Members", "#{e.to_s}\n\n#{$@[0..9] * "\n\t"}", { :member => member.inspect })
        Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
      end
    end
  end

  def self.send_pillar_emails 
    base = ActiveRecord::Base.connection.execute("SELECT memberships.member_id,email_templates.id FROM memberships INNER JOIN terms_of_memberships ON terms_of_memberships.id = memberships.terms_of_membership_id INNER JOIN email_templates ON email_templates.terms_of_membership_id = terms_of_memberships.id WHERE (email_templates.template_type = 'pillar' AND date(join_date) = DATE_SUB(CURRENT_DATE(), INTERVAL email_templates.days_after_join_date DAY) AND status IN ('active','provisional'))")
    Rails.logger.info " *** [#{I18n.l(Time.zone.now, :format =>:dashed)}] Starting members:send_pillar_emails rake task, processing #{base.count} templates"
    base.to_enum.with_index.each do |res,index|
      begin
        tz = Time.zone.now
        member = Member.find res[0]
        template = EmailTemplate.find res[1]
        Rails.logger.info "   *[#{index+1}] processing member ##{member.id}"
        Communication.deliver!(template, member)
        Rails.logger.info "    ... took #{Time.zone.now - tz}seconds for member ##{member.id}"
      rescue Exception => e
        Auditory.report_issue("Members::SendPillar", "#{e.to_s}\n\n#{$@[0..9] * "\n\t"}", { :template => template.inspect, :membership => member.current_membership.inspect })
        Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
      end
    end
  rescue Exception => e
    Auditory.report_issue("Members::SendPillar", e, {:backtrace => "#{$@[0..9] * "\n\t"}"})
    Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
  end

  # Method used from rake task and also from tests!
  def self.reset_club_cash_up_today
    base = Member.includes(:club).where("date(club_cash_expire_date) <= ? AND clubs.api_type != 'Drupal::Member' AND club_cash_enable = true", Time.zone.now.to_date).limit(2000)
    Rails.logger.info " *** [#{I18n.l(Time.zone.now, :format =>:dashed)}] Starting members:reset_club_cash_up_today rake task, processing #{base.count} members"
    base.to_enum.with_index.each do |member,index|
      tz = Time.zone.now
      begin
        Rails.logger.info "  *[#{index+1}] processing member ##{member.id}"
        member.reset_club_cash
      rescue Exception => e
        Auditory.report_issue("Member::ClubCash", "#{e.to_s}\n\n#{$@[0..9] * "\n\t"}", { :member => member.inspect })
        Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
      end
      Rails.logger.info "    ... took #{Time.zone.now - tz}seconds for member ##{member.id}"
    end
  rescue Exception => e
    Auditory.report_issue("Members::ClubCash", e, {:backtrace => "#{$@[0..9] * "\n\t"}"})
    Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
  end

  # Method used from rake task and also from tests!
  def self.cancel_all_member_up_today
    base =  Member.includes(:current_membership).where("date(memberships.cancel_date) <= ? AND memberships.status != ? ", Time.zone.now.to_date, 'lapsed')
    base_for_manual_payment = Member.includes(:current_membership).where("manual_payment = true AND date(bill_date) < ? AND memberships.status != ?", Time.zone.now.to_date, 'lapsed')
   
    [base, base_for_manual_payment].each do |list|
      Rails.logger.info " *** [#{I18n.l(Time.zone.now, :format =>:dashed)}] Starting members:cancel_all_member_up_today rake task, processing #{base.count} members"
      list.each_with_index do |member, index| 
        tz = Time.zone.now
        begin
          Rails.logger.info "  *[#{index+1}] processing member ##{member.id}"
          member.cancel!(Time.zone.now.in_time_zone(member.get_club_timezone), "Billing date is overdue.", nil, Settings.operation_types.bill_overdue_cancel) if member.manual_payment and not member.cancel_date
          member.set_as_canceled!
        rescue Exception => e
          Auditory.report_issue("Members::Cancel", "#{e.to_s}\n\n#{$@[0..9] * "\n\t"}", { :member => member.inspect })
          Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
        end
        Rails.logger.info "    ... took #{Time.zone.now - tz}seconds for member ##{member.id}"
      end
    end
  rescue Exception => e
    Auditory.report_issue("Members::Cancel", e, {:backtrace => "#{$@[0..9] * "\n\t"}"})
    Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
  end

  def self.process_sync 
    base = Member.where('status = "lapsed" AND api_id != "" and ( last_sync_error not like "There is no user with ID%" or last_sync_error is NULL )')
    tz = Time.zone.now
    Rails.logger.info " *** [#{I18n.l(Time.zone.now, :format =>:dashed)}] Starting members:process_sync rake task with members lapsed and api_id not null, processing #{base.count} members"
    base.find_in_batches do |group|
      group.each do |member|
        begin
          api_m = member.api_member
          unless api_m.nil?
            api_m.destroy!
            Auditory.audit(nil, member, "Member's drupal account destroyed by batch script", member, Settings.operation_types.member_drupal_account_destroyed_batch)
          end
        rescue Exception => e
          Auditory.report_issue("Members::Sync", e, {:member => member.inspect})
          Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
        end
      end
    end
    Rails.logger.info "    ... took #{Time.zone.now - tz}seconds"

    base = Member.where('last_sync_error like "There is no user with ID%"')
    base2 = Member.where('status = "lapsed" and last_sync_error like "%The e-mail address%is already taken%"')
    Rails.logger.info " *** [#{I18n.l(Time.zone.now, :format =>:dashed)}] Starting members:process_sync rake task with members with error sync related to wrong api_id, processing #{base.count+base2.count} members"
    tz = Time.zone.now
    index = 0
    [base,base2].each do |group|
      group.each do |member|
        begin
          Rails.logger.info "  *[#{index+1}] processing member ##{member.id}"
          member.api_id = nil 
          member.last_sync_error = nil
          member.last_sync_error_at = nil
          member.last_synced_at = nil
          member.sync_status = "not_synced"
          member.save(:validate => false)
          unless member.lapsed?
            api_m = member.api_member
            unless api_m.nil?
              if api_m.save!(force: true)
                unless member.last_sync_error_at
                  Auditory.audit(nil, member, "Member synchronized by batch script", member, Settings.operation_types.member_drupal_account_synced_batch)
                end
              end
            end
          end
          index = index + 1
        rescue Exception => e
          Auditory.report_issue("Members::Sync", e, {:member => member.inspect})
          Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
        end
      end
    end
    Rails.logger.info "    ... took #{Time.zone.now - tz}seconds"

    base = Member.joins(:club).where("sync_status IN ('with_error', 'not_synced') AND status != 'lapsed' AND clubs.api_type != '' ").limit(2000)
    Rails.logger.info " *** [#{I18n.l(Time.zone.now, :format =>:dashed)}] Starting members:process_sync rake task with members not_synced or with_error, processing #{base.count} members"
    tz = Time.zone.now
    base.to_enum.with_index.each do |member,index|
      begin
        Rails.logger.info "  *[#{index+1}] processing member ##{member.id}"
        api_m = member.api_member
        unless api_m.nil?
          if api_m.save!(force: true)
            unless member.last_sync_error_at
              Auditory.audit(nil, member, "Member synchronized by batch script", member, Settings.operation_types.member_drupal_account_synced_batch)
            end
          end
        end
      rescue Exception => e
        Auditory.report_issue("Members::Sync", e, {:member => member.inspect})
        Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
      end
    end       
    Rails.logger.info "    ... took #{Time.zone.now - tz}seconds"

  rescue Exception => e
    Auditory.report_issue("Members::Sync", e, {:backtrace => "#{$@[0..9] * "\n\t"}"})
    Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
  end

  def self.process_email_sync_error
    member_list = {}
    base = Member.where("sync_status = 'with_error' AND last_sync_error like '%The e-mail address%is already taken%'")
    Rails.logger.info " *** [#{I18n.l(Time.zone.now, :format =>:dashed)}] Starting members:process_email_sync_error rake task, processing #{base.count} members"
    base.find_in_batches do |group|
      group.each_with_index do |member, index|
        club = member.club
        row = "ID: #{member.id} - Partner-Club: #{club.partner.name}-#{club.name} - Email: #{member.email} - Status: #{member.status} - Drupal domain link: #{member.club.api_domain.url}/admin/people}"
        member_list.merge!("member#{index+1}" => row)
      end
    end
    Auditory.report_issue("Members::DuplicatedEmailSyncError.", "The following members are having problems with the syncronization due to duplicated emails.", member_list, false) unless member_list.empty?
  rescue Exception => e
    Auditory.report_issue("Members::SyncErrorEmail", e, {:backtrace => "#{$@[0..9] * "\n\t"}"})
    Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"  
  end

  def self.send_happy_birthday
    today = Time.zone.now.to_date
    base = Member.billable.where(" birth_date IS NOT NULL and DAYOFMONTH(birth_date) = ? and MONTH(birth_date) = ? ", 
      today.day, today.month)
    Rails.logger.info " *** [#{I18n.l(Time.zone.now, :format =>:dashed)}] Starting members:send_happy_birthday rake task, processing #{base.count} members"
    base.find_in_batches do |group|
      group.to_enum.with_index.each do |member,index| 
        tz = Time.zone.now
        begin
          Rails.logger.info "  *[#{index+1}] processing member ##{member.id}"
          Communication.deliver!(:birthday, member)
        rescue Exception => e
          Auditory.report_issue("Members::sendHappyBirthday", "#{e.to_s}\n\n#{$@[0..9] * "\n\t"}", { :member => member.inspect })
          Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
        end
        Rails.logger.info "    ... took #{Time.zone.now - tz}seconds for member ##{member.id}"
      end
    end
  rescue Exception => e
    Auditory.report_issue("Members::sendHappyBirthday", e, {:backtrace => "#{$@[0..9] * "\n\t"}"})
    Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
  end

  def self.send_prebill
    base = Member.joins(:current_membership => :terms_of_membership).where(
                          ["((date(next_retry_bill_date) = ? AND recycled_times = 0) 
                           OR (date(next_retry_bill_date) = ? AND manual_payment = true)) 
                           AND terms_of_memberships.installment_amount != 0.0 
                           AND terms_of_memberships.is_payment_expected = true", 
                           (Time.zone.now + 7.days).to_date, (Time.zone.now + 14.days).to_date 
                          ])

    base.find_in_batches do |group|
      group.each_with_index do |member,index| 
        tz = Time.zone.now
        begin
          Rails.logger.info "  *[#{index+1}] processing member ##{member.id}"
          member.send_pre_bill
        rescue Exception => e
          Auditory.report_issue("Billing::SendPrebill", "#{e.to_s}\n\n#{$@[0..9] * "\n\t"}", { :member => member.inspect })
          Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
        end
        Rails.logger.info "    ... took #{Time.zone.now - tz}seconds for member ##{member.id}"
      end
    end
  rescue Exception => e
    Auditory.report_issue("Members::SendPrebill", e, {:backtrace => "#{$@[0..9] * "\n\t"}"})
    Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
  end

  def self.sync_to_exact_target
    base = Member.where("need_exact_target_sync = 1")
    base.find_in_batches do |group|
      tz = Time.zone.now
      group.each_with_index do |member,index|
        begin
          Rails.logger.info "  *[#{index+1}] processing member ##{member.id}"
          member.marketing_tool_sync_without_dj
        rescue Exception => e
          Auditory.report_issue("Member::SyncExactTargetWithBatch", "#{e.to_s}\n\n#{$@[0..9] * "\n\t"}", { :member => member.inspect }) unless e.to_s.include?("Timeout")
          Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"        
        end
        Rails.logger.info "    ... took #{Time.zone.now - tz}seconds for member ##{member.id}"
      end
    end
  end

  def self.send_hot_rod_magazine_cancellation_email
    require 'csv'
    if Rails.env=='prototype'
      club = Club.find 48
    elsif Rails.env=='production'
      club = Club.find 9
    elsif Rails.env=='staging'
      club = Club.find 21
    end
    Time.zone = club.time_zone
    initial_date = Time.zone.now - 7.days
    end_date = Time.zone.now 
    members = Member.joins(:current_membership).where(["members.club_id = ? AND memberships.status = 'lapsed' AND
      cancel_date BETWEEN ? and ? ", club.id, initial_date, end_date])
    unless members.empty?
      temp_file = "#{I18n.l(Time.zone.now, :format => :only_date)}_magazine_cancellation.csv"
      CSV.open(temp_file, "w") do |csv|
        csv << ["RecType", "FHID", "PubCode", "Email", "CustomerCode", "CheckDigit", 
          "Keyline", "ISSN", "FirstName", "LastName", "JobTitle", "Company", "Address", "SupAddress", 
          "City", "State", "Zip", "Country", "CountryCode", "BusPhone", "HomePhone", "FaxPhone", 
          "ZFTerm", "AgentID", "AuditCode", "VersionCode", "PromoCode", "StartIssue", "EndIssue", 
          "Term", "CurrencyCode", "GrossPrice", "NetPrice", "IssuesRemaining", "OrderNumber", 
          "AutoRenew", "UMC", "Premium", "PayStatus","SubType", "TimesRenewed", "FutureUse"]
        members.each do |member|
          begin
            tz = Time.zone.now
            Rails.logger.info " *** Processing member #{member.id}"
            csv << [ '', '', '', member.email, member.email, '', '', '', member.first_name, member.last_name, '', '',
                  member.address, '', member.city, member.state, member.zip, member.country, '', '', '', '', '-8',
                  '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'cancel', '', '', '' ]
            Rails.logger.info " *** It took #{Time.zone.now - tz}seconds to process member #{member.id}"
          rescue Exception => e
            Auditory.report_issue("Members::HotRodMagazineCancellation", e, {:backtrace => "#{$@[0..9] * "\n\t"}"})
            Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
          end
        end
      end
    end
    Notifier.hot_rod_magazine_cancellation(File.read(temp_file), members.count).deliver!
    File.delete(temp_file)
  end

  #######################################################
  ################ FULFILLMENT ##########################
  #######################################################

  def self.process_fulfillments_up_today
    index = 0
    Fulfillment.to_be_renewed.find_in_batches do |group|
      Rails.logger.info " *** [#{I18n.l(Time.zone.now, :format =>:dashed)}] Starting members:process_fulfillments_up_today rake task, processing #{group.count} fulfillments"
      group.each do |fulfillment| 
        begin
          index = index+1
          Rails.logger.info "  *[#{index}] processing member ##{fulfillment.member_id} fulfillment ##{fulfillment.id}"
          fulfillment.renew!
        rescue Exception => e
          Auditory.report_issue("Member::Fulfillment", "#{e.to_s}\n\n#{$@[0..9] * "\n\t"}", { :fulfillment => fulfillment.inspect })
          Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
        end
      end
    end
  end

  #######################################################
  ################ FULFILLMENT ##########################
  #######################################################


end