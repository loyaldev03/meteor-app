namespace :billing do
  desc "Find members that have NBD for today. and bill them all!"
  # This task should be run each day at 3 am ?
  task :for_today => :environment do
    Rails.logger = Logger.new("#{Rails.root}/log/billing_for_today.log")
    Rails.logger.level = Logger::DEBUG
    ActiveRecord::Base.logger = Rails.logger
    tall = Time.zone.now
    begin
      Member.bill_all_members_up_today
    ensure
      Rails.logger.info "It all took #{Time.zone.now - tall} to run billing:for_today task"
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
      Member.send_prebill
    ensure
      Rails.logger.info "It all took #{Time.zone.now - tall} to run billing:send_prebill task"
    end
  end
end

namespace :members do
  desc "Refresh autologin_url for ALL members"
  task :Members => :environment do
    Rails.logger = Logger.new("#{Rails.root}/log/members_members.log")
    Rails.logger.level = Logger::DEBUG
    ActiveRecord::Base.logger = Rails.logger
    tall = Time.zone.now
    begin
      Rails.logger.info "*** [#{I18n.l(Time.zone.now, :format =>:dashed)}] Starting members:refresh_autologin_url rake task, processing #{Member.count} members"
      Member.find_each do |member|
        begin
          Rails.logger.info "   * processing member ##{member.id}"
          member.refresh_autologin_url!
        rescue
          Airbrake.notify error_class: "Members::Members", 
            error_message: "#{e.to_s}\n\n#{$@[0..9] * "\n\t"}", :parameters => { :member => member.inspect }
          Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
        end
      end
    rescue
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
      Member.cancel_all_member_up_today
    ensure
      Rails.logger.info "It all took #{Time.zone.now - tall} to run members:cancel task"
    end
  end


  desc "Sync members to pardot"
  # This task should be run each day at 3 am ?
  task :sync_members_to_pardot => :environment do
    Rails.logger = Logger.new("#{Rails.root}/log/members_sync_members_to_pardot.log")
    Rails.logger.level = Logger::DEBUG
    ActiveRecord::Base.logger = Rails.logger
    tall = Time.zone.now
    begin
      Member.sync_members_to_pardot
    ensure
      Rails.logger.info "It all took #{Time.zone.now - tall} to run members:sync_members_to_pardot task"
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
      Member.send_happy_birthday
    ensure
      Rails.logger.info "It all took #{Time.zone.now - tall} to run members:send_happy_birthday task"
    end
  end

  desc "Send pillar emails"
  task :send_pillar_emails => :environment do 
    Rails.logger = Logger.new("#{Rails.root}/log/members_send_pillar_emails.log")
    Rails.logger.level = Logger::DEBUG
    ActiveRecord::Base.logger = Rails.logger
    tall = Time.zone.now
    begin
      Member.send_pillar_emails
    ensure
      Rails.logger.info "It all took #{Time.zone.now - tall} to run members:send_pillar_emails task"
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
      Member.reset_club_cash_up_today
    ensure
      Rails.logger.info "It all took #{Time.zone.now - tall} to run members:process_club_cash task"
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
      Fulfillment.process_fulfillments_up_today
    ensure
      Rails.logger.info "It all took #{Time.zone.now - tall} to run members:process_fulfillments task"
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
      Member.process_sync
    ensure 
      Rails.logger.info "It all took #{Time.zone.now - tall} to run members:process_sync task"
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
      Member.process_email_sync_error
    ensure 
      Rails.logger.info "It all took #{Time.zone.now - tall} to run members:process_email_sync_error task"
    end 
  end
end