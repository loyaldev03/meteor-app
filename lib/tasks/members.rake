namespace :billing do
  desc "Find members that have NBD for today. and bill them all!"
  # This task should be run each day at 3 am ?
  task :for_today => :environment do
    tall = Time.now
    begin
      Member.find_in_batches(:conditions => [" date(next_retry_bill_date) <= ? ", Date.today]) do |group|
        group.each do |member| 
          tz = Time.now
          begin
            Rails.logger.info "  * processing member ##{member.uuid}"
            member.bill_membership
          rescue Exception => e
            Auditory.add_redmine_ticket('Billing::Today', e.to_s)
            Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
          end
          Rails.logger.info "    ... took #{Time.now - tz} for member ##{member.id}"
        end
        sleep(5) # Make sure it doesn't get too crowded in there!
      end
    ensure
      Rails.logger.info "It all took #{Time.now - tall}"
    end
  end

  desc "Send prebill emails"
  # This task should be run each day at 3 am ?
  task :send_prebill => :environment do
    tall = Time.now
    begin
      # We use bill_date because we will only send this email once!
      Member.find_in_batches(:conditions => [" date(bill_date) = ? ", Date.today + 7.days ]) do |group|
        group.each do |member| 
          tz = Time.now
          begin
            Rails.logger.info "  * processing member ##{member.uuid}"
            member.send_pre_bill
          rescue Exception => e
            Auditory.add_redmine_ticket('Billing::SendPrebill', e.to_s)
            Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
          end
          Rails.logger.info "    ... took #{Time.now - tz} for member ##{member.id}"
        end
        sleep(5) # Make sure it doesn't get too crowded in there!
      end
    ensure
      Rails.logger.info "It all took #{Time.now - tall}"
    end
  end
end

namespace :members do
  desc "Cancel members"
  # This task should be run each day at 3 am ?
  task :cancel => :environment do
    tall = Time.now
    begin
      base =  Member.where(" date(cancel_date) <= ? AND status != ? ", Date.today, 'lapsed')
      Rails.logger.info " *** Starting members:cancel rake task, processing #{base.count} members"
      base.find_in_batches do |group|
        group.each do |member| 
          tz = Time.now
          begin
            Rails.logger.info "  * processing member ##{member.uuid}"
            member.set_as_canceled!
          rescue Exception => e
            Auditory.add_redmine_ticket('Members::Cancel', e.to_s)
            Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
          end
          Rails.logger.info "    ... took #{Time.now - tz} for member ##{member.id}"
        end
        sleep(5) # Make sure it doesn't get too crowded in there!
      end
    ensure
      Rails.logger.info "It all took #{Time.now - tall}"
    end
  end

  desc "Process fulfillments"
  # This task should be run each day at 3 am 
  task :process_fulfillments => :environment do
    tall = Time.now
    begin
      Fulfillment.find_in_batches(:conditions => [" date(renewable_at) <= ? and status = ? ", Date.today, 'open' ]) do |group|
        group.each do |fulfillment| 
          tz = Time.now
          begin
            Rails.logger.info "  * processing member ##{fulfillment.member.uuid} fulfillment ##{fulfillment.id}"
            fulfillment.renew
          rescue Exception => e
            Auditory.add_redmine_ticket('Member::Fulfillment', e.to_s)
            Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
          end
          Rails.logger.info "    ... took #{Time.now - tz} for member ##{member.id}"
        end
        sleep(5) # Make sure it doesn't get too crowded in there!
      end
    ensure
      Rails.logger.info "It all took #{Time.now - tall}"
    end
  end
end
