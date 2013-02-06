namespace :billing do
  desc "Find members that have NBD for today. and bill them all!"
  # This task should be run each day at 3 am ?
  task :for_today => :environment do
    tall = Time.zone.now
    begin
      Member.bill_all_members_up_today
    ensure
      Rails.logger.info "It all took #{Time.zone.now - tall}"
    end
  end

  desc "Send prebill emails"
  # This task should be run each day at 3 am ?
  task :send_prebill => :environment do
    tall = Time.zone.now
    begin
      # We use bill_date because we will only send this email once!
      Member.find_in_batches(:conditions => [" date(bill_date) = ? ", (Time.zone.now + 7.days).to_date ]) do |group|
        group.each do |member| 
          tz = Time.zone.now
          begin
            Rails.logger.info "  * processing member ##{member.uuid}"
            member.send_pre_bill
          rescue Exception => e
            Airbrake.notify(:error_class => "Billing::SendPrebill", :error_message => "#{e.to_s}\n\n#{$@[0..9] * "\n\t"}", :parameters => { :member => member.inspect })
            Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
          end
          Rails.logger.info "    ... took #{Time.zone.now - tz} for member ##{member.id}"
        end
      end
    ensure
      Rails.logger.info "It all took #{Time.zone.now - tall}"
    end
  end
end

namespace :members do
  desc "Refresh autologin_url for ALL members"
  task :Members => :environment do
    tall = Time.zone.now
    begin
      Rails.logger.info " *** Starting members:refresh_autologin_url rake task, processing #{Member.count} members"
      Member.find_each do |member|
        begin
          Rails.logger.info "   * processing member ##{member.uuid}"
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
    tall = Time.zone.now
    begin
      Member.cancel_all_member_up_today
    ensure
      Rails.logger.info "It all took #{Time.zone.now - tall}"
    end
  end


  desc "Sync members to pardot"
  # This task should be run each day at 3 am ?
  task :sync_members_to_pardot => :environment do
    tall = Time.zone.now
    begin
      Member.sync_members_to_pardot
    ensure
      Rails.logger.info "It all took #{Time.zone.now - tall}"
    end
  end

  desc "Send Happy birthday email to members"
  # This task should be run each day at 3 am ?
  task :send_happy_birthday => :environment do
    tall = Time.zone.now
    begin
      Member.send_happy_birthday
    ensure
      Rails.logger.info "It all took #{Time.zone.now - tall}"
    end
  end

  desc "Send pillar emails"
  task :send_pillar_emails => :environment do 
    tall = Time.zone.now
    begin
      Member.send_pillar_emails
    ensure
      Rails.logger.info "It all took #{Time.zone.now - tall}"
    end
  end

  desc "Process club cash"
  # This task should be run each day at 3 am 
  task :process_club_cash => :environment do
    tall = Time.zone.now
    begin
      Member.reset_club_cash_up_today
    ensure
      Rails.logger.info "It all took #{Time.zone.now - tall}"
    end
  end

  desc "Process fulfillments"
  # This task should be run each day at 3 am 
  task :process_fulfillments => :environment do
    tall = Time.zone.now
    begin
      Fulfillment.process_fulfillments_up_today
    ensure
      Rails.logger.info "It all took #{Time.zone.now - tall}"
    end
  end

  desc "Process sync of member"
  # This task should be run every X hours.
  task :process_sync => :environment do
    tall = Time.zone.now
    begin
      Member.process_sync
    ensure 
      Rails.logger.info "It all took #{Time.zone.now - tall}"
    end
  end

  desc "Process members with duplicated emails errors on sync"
  # This task should be run every X hours. 
  task :process_email_sync_error => :environment do
    tall = Time.zone.now
    begin
      Member.process_email_sync_error
    ensure 
      Rails.logger.info "It all took #{Time.zone.now - tall}"
    end 
  end
end