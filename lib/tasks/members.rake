require 'tasks/tasks_helpers'

namespace :billing do
  desc "Find members that have NBD for today. and bill them all!"
  # This task should be run each day at 3 am ?
  task :for_today => :environment do
    Rails.logger = Logger.new("#{Rails.root}/log/billing_for_today.log")
    Rails.logger.level = Logger::DEBUG
    ActiveRecord::Base.logger = Rails.logger
    tall = Time.zone.now
    begin
      TasksHelpers.bill_all_members_up_today
    ensure
      Rails.logger.info "It all took #{Time.zone.now - tall}seconds to run billing:for_today task"
    end
  end

  desc "Send prebill emails"
  # This task should be run each day at 3 am ?
  task :send_prebill => :environment do
    Rails.logger = Logger.new("#{Rails.root}/log/billing_send_prebill.log")
    Rails.logger.level = Logger::DEBUG
    ActiveRecord::Base.logger = Rails.logger
    tall = Time.zone.now
    begin
      # We use bill_date because we will only send this email once!
      TasksHelpers.send_prebill
    ensure
      Rails.logger.info "It all took #{Time.zone.now - tall}seconds to run billing:send_prebill task"
    end
  end
end

namespace :users do
  desc "Refresh autologin_url for ALL members"
  task :Members => :environment do
    begin
      Rails.logger = Logger.new("#{Rails.root}/log/members_members.log")
      Rails.logger.level = Logger::DEBUG
      ActiveRecord::Base.logger = Rails.logger
      tall = Time.zone.now
      Rails.logger.info "*** [#{I18n.l(Time.zone.now, :format =>:dashed)}] Starting members:refresh_autologin_url rake task, processing #{User.count} members"
      TasksHelpers.refresh_autologin
    rescue Exception => e
      Auditory.report_issue("Users::Users", e, {:backtrace => "#{$@[0..9] * "\n\t"}"})
      Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"})"
    end    
  end

  desc "Cancel members"
  # This task should be run each day at 3 am ?
  task :cancel => :environment do
    Rails.logger = Logger.new("#{Rails.root}/log/members_cancel.log")
    Rails.logger.level = Logger::DEBUG
    ActiveRecord::Base.logger = Rails.logger
    tall = Time.zone.now
    begin
      TasksHelpers.cancel_all_member_up_today
    ensure
      Rails.logger.info "It all took #{Time.zone.now - tall}seconds to run members:cancel task"
    end
  end

  desc "Process scheduled TOM changes"
  # This task should be run each day at 3 am ?
  task :process_scheduled_membership_changes => :environment do
    Rails.logger = Logger.new("#{Rails.root}/log/members_process_scheduled_membership_changes.log")
    Rails.logger.level = Logger::DEBUG
    ActiveRecord::Base.logger = Rails.logger
    tall = Time.zone.now
    begin
      TasksHelpers.process_scheduled_membership_changes
    ensure
      Rails.logger.info "It all took #{Time.zone.now - tall}seconds to run members:process_scheduled_membership_changes task"
    end
  end

  desc "Send Happy birthday email to members"
  # This task should be run each day at 3 am ?
  task :send_happy_birthday => :environment do
    Rails.logger = Logger.new("#{Rails.root}/log/members_send_happy_birthday.log")
    Rails.logger.level = Logger::DEBUG
    ActiveRecord::Base.logger = Rails.logger
    tall = Time.zone.now
    begin
      TasksHelpers.send_happy_birthday
    ensure
      Rails.logger.info "It all took #{Time.zone.now - tall}seconds to run members:send_happy_birthday task"
    end
  end

  desc "Send pillar emails"
  task :send_pillar_emails => :environment do 
    Rails.logger = Logger.new("#{Rails.root}/log/members_send_pillar_emails.log")
    Rails.logger.level = Logger::DEBUG
    ActiveRecord::Base.logger = Rails.logger
    tall = Time.zone.now
    begin
      TasksHelpers.send_pillar_emails
    ensure
      Rails.logger.info "It all took #{Time.zone.now - tall}seconds to run members:send_pillar_emails task"
    end
  end

  desc "Process club cash"
  # This task should be run each day at 3 am 
  task :process_club_cash => :environment do
    Rails.logger = Logger.new("#{Rails.root}/log/members_process_club_cash.log")
    Rails.logger.level = Logger::DEBUG
    ActiveRecord::Base.logger = Rails.logger
    tall = Time.zone.now
    begin
      TasksHelpers.reset_club_cash_up_today
    ensure
      Rails.logger.info "It all took #{Time.zone.now - tall}seconds to run members:process_club_cash task"
    end
  end

  desc "Process fulfillments"
  # This task should be run each day at 3 am 
  task :process_fulfillments => :environment do
    Rails.logger = Logger.new("#{Rails.root}/log/members_process_fulfillments.log")
    Rails.logger.level = Logger::DEBUG
    ActiveRecord::Base.logger = Rails.logger
    tall = Time.zone.now
    begin
      TasksHelpers.process_fulfillments_up_today
    ensure
      Rails.logger.info "It all took #{Time.zone.now - tall}seconds to run members:process_fulfillments task"
    end
  end

  desc "Process sync of member"
  # This task should be run every X hours.
  task :process_sync => :environment do
    Rails.logger = Logger.new("#{Rails.root}/log/members_process_sync.log")
    Rails.logger.level = Logger::DEBUG
    ActiveRecord::Base.logger = Rails.logger
    tall = Time.zone.now
    begin
      TasksHelpers.process_sync
    ensure 
      Rails.logger.info "It all took #{Time.zone.now - tall}seconds to run members:process_sync task"
    end
  end

  desc "Process members with duplicated emails errors on sync"
  # This task should be run every X hours. 
  task :process_email_sync_error => :environment do
    Rails.logger = Logger.new("#{Rails.root}/log/members_process_email_sync_error.log")
    Rails.logger.level = Logger::DEBUG
    ActiveRecord::Base.logger = Rails.logger
    tall = Time.zone.now
    begin
      TasksHelpers.process_email_sync_error
    ensure 
      Rails.logger.info "It all took #{Time.zone.now - tall}seconds to run members:process_email_sync_error task"
    end 
  end

  desc "Sync all members available"
  task :sync_all_to_drupal => :environment do
    Rails.logger = Logger.new("#{Rails.root}/log/sync_all.log")
    Rails.logger.level = Logger::DEBUG
    ActiveRecord::Base.logger = Rails.logger
    tall = Time.zone.now

    #club_id = 1 #WE HAVE TO SET THIS VAlUE.
    members = User.where("status != 'lapsed' and sync_status = 'synced' and club_id = ?",club_id)

    members.find_in_batches(:batch_size=>40) do |group|
      tall = Time.zone.now
      group.each do |member|
        api_m = member.api_user
        begin
          if api_m.save!(force: true)
            if member.last_sync_error_at
              Rails.logger.info "Member #{member.id} was not successfully synced: Error: #{member.last_sync_error_at}."
            else
              Rails.logger.info "Member #{member.id} successfully synced."
            end
          end
        rescue
          Rails.logger.info "Member #{member.id} not synced because of Timeout"
        end
      end
      time_to_sleep = Time.zone.now-tall
    sleep(time_to_sleep) if time_to_sleep > 0
    end
    Rails.logger.info "Finished running members:sync_all_to_drupal task"
  end

  desc "Delete every user with testing_account flag as true"
  task :delete_testing_accounts => :environment do
    Rails.logger = Logger.new("#{Rails.root}/log/destroy_testing_accounts.log")
    Rails.logger.level = Logger::DEBUG
    ActiveRecord::Base.logger = Rails.logger
    tall = Time.zone.now
    Rails.logger.info " *** [#{I18n.l(Time.zone.now, :format =>:dashed)}] Starting rake task"
    begin 
      TasksHelpers.delete_testing_accounts
    ensure
      Rails.logger.info "It all took #{Time.zone.now - tall}seconds to run task"        
    end  
  end

end