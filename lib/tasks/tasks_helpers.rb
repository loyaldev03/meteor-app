module TasksHelpers
  #######################################################
  ################ MEMBER ###############################
  #######################################################

  # Method used from rake task and also from tests!
  def self.bill_all_members_up_today
    file = File.open("/tmp/bill_all_members_up_today_#{Rails.env}.lock", File::RDWR|File::CREAT, 0644)
    file.flock(File::LOCK_EX)

    base = User.joins(:current_membership => :terms_of_membership).where("DATE(next_retry_bill_date) <= ? AND users.club_id IN (select id from clubs where billing_enable = true) AND users.status NOT IN ('applied','lapsed') AND manual_payment = false AND terms_of_memberships.is_payment_expected = 1", Time.zone.now.to_date).limit(4000)
    Rails.logger.info " *** [#{I18n.l(Time.zone.now, :format =>:dashed)}] Starting users:billing rake task, processing #{base.length} users"
    base.to_enum.with_index.each do |user,index| 
      tz = Time.zone.now
      begin
        Rails.logger.info "  *[#{index+1}] processing user ##{user.id} nbd: #{user.next_retry_bill_date}"
        user.bill_membership
      rescue Exception => e
        Auditory.report_issue("Billing::Today", e, { :user => user.inspect, :credit_card => user.active_credit_card.inspect })
        Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
      end
      Rails.logger.info "    ... took #{Time.zone.now - tz}seconds for user ##{user.id}"
    end
    file.flock(File::LOCK_UN)
  rescue Exception => e
    Auditory.report_issue("Billing::Today", e, {:backtrace => "#{$@[0..9] * "\n\t"}"})
    Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
  end

  def self.refresh_autologin
    index = 0
    User.find_each do |user|
      begin
        index = index+1
        Rails.logger.info "   *[#{index}] processing user ##{user.id}"
        user.refresh_autologin_url!
      rescue
        Auditory.report_issue("Users::Users", e, { :user => user.inspect })
        Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
      end
    end
  end

  def self.send_pillar_emails 
    base = Membership.joins(:user).joins(:terms_of_membership).joins(:terms_of_membership => :club).joins(:terms_of_membership => :email_templates).
           where("email_templates.template_type = 'pillar' AND email_templates.client = clubs.marketing_tool_client AND date(join_date) = DATE_SUB(?, INTERVAL email_templates.days DAY) AND users.status IN ('active','provisional') and billing_enable = true", Time.zone.now.to_date).
           select("memberships.user_id, email_templates.id")
    Rails.logger.info " *** [#{I18n.l(Time.zone.now, :format =>:dashed)}] Starting members:send_pillar_emails rake task, processing #{base.length} templates"
    base.to_enum.with_index.each do |res,index|
      begin
        tz = Time.zone.now
        user = User.find res.user_id
        template = EmailTemplate.find res.id
        Rails.logger.info "   *[#{index+1}] processing user ##{user.id}"
        Communication.deliver!(template, user)
        Rails.logger.info "    ... took #{Time.zone.now - tz}seconds for user ##{user.id}"
      rescue Exception => e
        Auditory.report_issue("Users::SendPillar", e, { :template => template.inspect, :membership => user.current_membership.inspect })
        Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
      end
    end
  rescue Exception => e
    Auditory.report_issue("Users::SendPillar", e, {:backtrace => "#{$@[0..9] * "\n\t"}"})
    Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
  end

  # Method used from rake task and also from tests!
  def self.reset_club_cash_up_today
    base = User.joins(:club).where("date(club_cash_expire_date) <= ? AND clubs.api_type != 'Drupal::Member' AND club_cash_enable = true", Time.zone.now.to_date).limit(2000)
    Rails.logger.info " *** [#{I18n.l(Time.zone.now, :format =>:dashed)}] Starting members:reset_club_cash_up_today rake task, processing #{base.length} users"
    base.to_enum.with_index.each do |user,index|
      tz = Time.zone.now
      begin
        Rails.logger.info "  *[#{index+1}] processing user ##{user.id}"
        user.reset_club_cash
      rescue Exception => e
        Auditory.report_issue("User::ClubCash", e, { :user => user.inspect })
        Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
      end
      Rails.logger.info "    ... took #{Time.zone.now - tz}seconds for user ##{user.id}"
    end
  rescue Exception => e
    Auditory.report_issue("Users::ClubCash", e, {:backtrace => "#{$@[0..9] * "\n\t"}"})
    Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
  end

  # Method used from rake task and also from tests!
  def self.cancel_all_member_up_today
    enabled_clubs = Club.where(billing_enable: true).pluck(:id)
    base = User.joins(:current_membership).where("club_id IN (?) AND date(memberships.cancel_date) <= ? AND memberships.status != ? ", enabled_clubs, Time.zone.now.to_date, 'lapsed')
    base_for_manual_payment = User.joins(:current_membership).where("club_id IN (?) AND manual_payment = true AND date(bill_date) < ? AND memberships.status != ?", enabled_clubs, Time.zone.now.to_date, 'lapsed')
   
    [base, base_for_manual_payment].each do |list|
      Rails.logger.info " *** [#{I18n.l(Time.zone.now, :format =>:dashed)}] Starting users:cancel_all_member_up_today rake task, processing #{base.length} users"
      list.each_with_index do |user, index| 
        tz = Time.zone.now
        begin
          Rails.logger.info "  *[#{index+1}] processing user ##{user.id}"
          user.cancel!(Time.zone.now.in_time_zone(user.get_club_timezone), "Billing date is overdue.", nil, Settings.operation_types.bill_overdue_cancel) if user.manual_payment and not user.cancel_date
          user.set_as_canceled!
        rescue Exception => e
          Auditory.report_issue("Users::Cancel", e, { :user => user.inspect })
          Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
        end
        Rails.logger.info "    ... took #{Time.zone.now - tz}seconds for user ##{user.id}"
      end
    end
  rescue Exception => e
    Auditory.report_issue("Users::Cancel", e, {:backtrace => "#{$@[0..9] * "\n\t"}"})
    Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
  end

  def self.process_sync 
    base = User.where('status = "lapsed" AND api_id != "" and ( last_sync_error not like "There is no user with ID%" or last_sync_error is NULL )').with_billing_enable.select('users.id')
    tz = Time.zone.now
    Rails.logger.info " *** [#{I18n.l(Time.zone.now, :format =>:dashed)}] Starting users:process_sync rake task with users lapsed and api_id not null, processing #{base.length} users"
    base.find_in_batches do |group|
      group.each do |user_id|
        begin
          user = User.find_by_id user_id
          api_m = user.api_user
          unless api_m.nil?
            api_m.destroy!
            Auditory.audit(nil, user, "User's drupal account destroyed by batch script", user, Settings.operation_types.user_drupal_account_destroyed_batch)
          end
        rescue Exception => e
          Auditory.report_issue("Users::Sync", e, {:user => (user.nil? ? user_id : user.inspect)})
          Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
        end
      end
    end
    Rails.logger.info "    ... took #{Time.zone.now - tz}seconds"

    base =  User.where('last_sync_error like "There is no user with ID%"').with_billing_enable.select('users.id')
    base2 = User.where('status = "lapsed" and last_sync_error like "%The e-mail address%is already taken%"').with_billing_enable.select('users.id')
    Rails.logger.info " *** [#{I18n.l(Time.zone.now, :format =>:dashed)}] Starting users:process_sync rake task with users with error sync related to wrong api_id, processing #{base.length+base2.length} users"
    tz = Time.zone.now
    index = 0
    [base,base2].each do |group|
      group.each do |user_id|
        begin
          Rails.logger.info "  *[#{index+1}] processing user ##{user_id}"
          user = User.find_by_id user_id
          user.api_id = nil 
          user.last_sync_error = nil
          user.last_sync_error_at = nil
          user.last_synced_at = nil
          user.sync_status = "not_synced"
          user.save(:validate => false)
          unless user.lapsed?
            api_m = user.api_user
            unless api_m.nil?
              if api_m.save!(force: true)
                unless user.last_sync_error_at
                  Auditory.audit(nil, user, "Member synchronized by batch script", user, Settings.operation_types.user_drupal_account_synced_batch)
                end
              end
            end
          end
          index = index + 1
        rescue Exception => e
          Auditory.report_issue("Users::Sync", e, {:user => (user.nil? ? user_id : user.inspect)})
          Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
        end
      end
    end
    Rails.logger.info "    ... took #{Time.zone.now - tz}seconds"

    base = User.joins(:club).where("sync_status IN ('with_error', 'not_synced') AND status != 'lapsed' AND clubs.api_type != '' ").with_billing_enable.select('users.id').limit(2000)
    Rails.logger.info " *** [#{I18n.l(Time.zone.now, :format =>:dashed)}] Starting users:process_sync rake task with users not_synced or with_error, processing #{base.length} users"
    tz = Time.zone.now
    base.to_enum.with_index.each do |user_id,index|
      begin
        Rails.logger.info "  *[#{index+1}] processing user ##{user_id}"
        user = User.find_by_id user_id
        api_m = user.api_user
        unless api_m.nil?
          if api_m.save!(force: true)
            unless user.last_sync_error_at
              Auditory.audit(nil, user, "Member synchronized by batch script", user, Settings.operation_types.user_drupal_account_synced_batch)
            end
          end
        end
      rescue Exception => e
        Auditory.report_issue("Users::Sync", e, {:user => (user.nil? ? user_id : user.inspect)})
        Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
      end
    end       
    Rails.logger.info "    ... took #{Time.zone.now - tz}seconds"

  rescue Exception => e
    Auditory.report_issue("Users::Sync", e, {:backtrace => "#{$@[0..9] * "\n\t"}"})
    Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
  end

  def self.process_email_sync_error
    user_list = {}
    base = User.where("sync_status = 'with_error' AND last_sync_error like '%The e-mail address%is already taken%'")
    Rails.logger.info " *** [#{I18n.l(Time.zone.now, :format =>:dashed)}] Starting users:process_email_sync_error rake task, processing #{base.length} users"
    base.find_in_batches do |group|
      group.each_with_index do |user, index|
        club = user.club
        row = "ID: #{user.id} - Partner-Club: #{club.partner.name}-#{club.name} - Email: #{user.email} - Status: #{user.status} - Drupal domain link: #{user.club.api_domain.url}/admin/people}"
        user_list.merge!("user#{index+1}" => row)
      end
    end
    Auditory.report_issue("Users::DuplicatedEmailSyncError.", "The following users are having problems with the syncronization due to duplicated emails.", user_list, false) unless user_list.empty?
  rescue Exception => e
    Auditory.report_issue("Users::SyncErrorEmail", e, {:backtrace => "#{$@[0..9] * "\n\t"}"})
    Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"  
  end

  def self.send_happy_birthday
    today = Time.zone.now.to_date
    base = User.billable.joins(:club).where(" birth_date IS NOT NULL and DAYOFMONTH(birth_date) = ? and MONTH(birth_date) = ? and billing_enable = true", today.day, today.month)
    Rails.logger.info " *** [#{I18n.l(Time.zone.now, :format =>:dashed)}] Starting users:send_happy_birthday rake task, processing #{base.length} users"
    base.find_in_batches do |group|
      group.to_enum.with_index.each do |user,index| 
        tz = Time.zone.now
        begin
          Rails.logger.info "  *[#{index+1}] processing user ##{user.id}"
          Communication.deliver!(:birthday, user)
        rescue Exception => e
          Auditory.report_issue("Users::sendHappyBirthday", e, { :user => user.inspect })
          Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
        end
        Rails.logger.info "    ... took #{Time.zone.now - tz}seconds for user ##{user.id}"
      end
    end
  rescue Exception => e
    Auditory.report_issue("Users::sendHappyBirthday", e, {:backtrace => "#{$@[0..9] * "\n\t"}"})
    Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
  end

  def self.send_prebill
    base = User.joins(current_membership: [terms_of_membership: :email_templates]).where(
    ["email_templates.template_type = 'prebill' AND ((date(next_retry_bill_date) = DATE_ADD(?, INTERVAL email_templates.days DAY) AND recycled_times = 0) 
     OR (date(next_retry_bill_date) = ? AND manual_payment = true))
     AND terms_of_memberships.installment_amount != 0.0 
     AND terms_of_memberships.is_payment_expected = true", 
     (Time.zone.now).to_date, (Time.zone.now + 14.days).to_date 
    ])

    Rails.logger.info " *** [#{I18n.l(Time.zone.now, :format =>:dashed)}] Starting users:send_prebill rake task, processing #{base.length} users"
    base.find_in_batches do |group|
      group.each_with_index do |user,index| 
        tz = Time.zone.now
        begin
          Rails.logger.info "  *[#{index+1}] processing user ##{user.id}"
          user.send_pre_bill
        rescue Exception => e
          Auditory.report_issue("Billing::SendPrebill", e, { :user => user.inspect })
          Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
        end
        Rails.logger.info "    ... took #{Time.zone.now - tz}seconds for user ##{user.id}"
      end
    end
  rescue Exception => e
    Auditory.report_issue("Users::SendPrebill", e, {:backtrace => "#{$@[0..9] * "\n\t"}"})
    Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
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
    initial_date = Time.zone.now - 1.month
    end_date = Time.zone.now 
    users = User.joins(:current_membership).where(["users.club_id = ? AND memberships.status = 'lapsed' AND
      cancel_date BETWEEN ? and ? ", club.id, initial_date, end_date])
    unless users.empty?
      temp_file = "#{I18n.l(Time.zone.now, :format => :only_date)}_magazine_cancellation.csv"
      CSV.open(temp_file, "w") do |csv|
        csv << ["RecType", "FHID", "PubCode", "Email", "CustomerCode", "CheckDigit", 
          "Keyline", "ISSN", "FirstName", "LastName", "JobTitle", "Company", "Address", "SupAddress", 
          "City", "State", "Zip", "Country", "CountryCode", "BusPhone", "HomePhone", "FaxPhone", 
          "ZFTerm", "AgentID", "AuditCode", "VersionCode", "PromoCode", "StartIssue", "EndIssue", 
          "Term", "CurrencyCode", "GrossPrice", "NetPrice", "IssuesRemaining", "OrderNumber", 
          "AutoRenew", "UMC", "Premium", "PayStatus","SubType", "TimesRenewed", "FutureUse"]
        users.each do |user|
          begin
            tz = Time.zone.now
            Rails.logger.info " *** Processing member #{user.id}"
            csv << [ '', '', '', user.email, user.email, '', '', '', user.first_name, user.last_name, '', '',
                  user.address, '', user.city, user.state, user.zip, user.country, '', '', '', '', '-8',
                  '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'cancel', '', '', '' ]
            Rails.logger.info " *** It took #{Time.zone.now - tz}seconds to process user #{user.id}"
          rescue Exception => e
            Auditory.report_issue("Users::HotRodMagazineCancellation", e, {:backtrace => "#{$@[0..9] * "\n\t"}"})
            Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
          end
        end
      end
      Notifier.hot_rod_magazine_cancellation(File.read(temp_file), users.count).deliver!
      File.delete(temp_file)
    end
  end

  def self.delete_testing_accounts
    today = Time.zone.now.to_date
    base = User.where(testing_account: true)
    Rails.logger.info " *** [#{I18n.l(Time.zone.now, :format =>:dashed)}] Starting users:delete_testing_accounts rake task, processing #{base.length} users"
    base.select{|user| user.transactions.where(success: true).sum(:amount)==0.0}.to_enum.with_index.each do |user,index| 
      tz = Time.zone.now
      begin
        Rails.logger.info "  *[#{index+1}] processing user ##{user.id}"
        user.marketing_tool_sync_unsubscription(false)
        Operation.delete_all(["user_id = ?", user.id])
        UserNote.delete_all(["user_id = ?", user.id])
        UserPreference.delete_all(["user_id = ?", user.id])
        CreditCard.delete_all(["user_id = ?", user.id])
        Transaction.delete_all(["user_id = ?", user.id])
        Fulfillment.delete_all(["user_id = ?", user.id])
        Communication.delete_all(["user_id = ?", user.id])
        ClubCashTransaction.delete_all(["user_id = ?", user.id])
        Membership.delete_all(["user_id = ?", user.id])
        user.cancel_user_at_remote_domain_without_delay
        user.index.remove user rescue nil
        user.delete
      rescue Exception => e
        Auditory.report_issue("Users::deleteTestingAccounts", e, { :user => user.id })
        Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
      end
      Rails.logger.info "    ... took #{Time.zone.now - tz}seconds for user ##{user.id}"
    end
  end


  #######################################################
  ################ FULFILLMENT ##########################
  #######################################################

  def self.process_fulfillments_up_today
    index = 0
    Fulfillment.to_be_renewed.find_in_batches do |group|
      Rails.logger.info " *** [#{I18n.l(Time.zone.now, :format =>:dashed)}] Starting users:process_fulfillments_up_today rake task, processing #{group.size} fulfillments"
      group.each do |fulfillment| 
        begin
          index = index+1
          Rails.logger.info "  *[#{index}] processing member ##{fulfillment.user_id} fulfillment ##{fulfillment.id}"
          fulfillment.renew!
        rescue Exception => e
          Auditory.report_issue("User::Fulfillment", e, { :fulfillment => fulfillment.inspect })
          Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
        end
      end
    end
  end

  #######################################################
  ################ FULFILLMENT ##########################
  #######################################################


end