namespace :billing do
  desc "Find members that have NBD for today. and bill them all!"
  # This task should be run each day at 3 am ?
  task :for_today => :environment do
    tall = Time.zone.now
    begin
      Member.find_in_batches(:conditions => [" date(next_retry_bill_date) <= ? ", Date.today]) do |group|
        group.each do |member| 
          tz = Time.zone.now
          begin
            Rails.logger.info "  * processing member ##{member.uuid}"
            member.bill_membership
          rescue Exception => e
            Airbrake.notify(:error_class => "Billing::Today", :error_message => "#{e.to_s}\n\n#{$@[0..9] * "\n\t"}")
            Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
          end
          Rails.logger.info "    ... took #{Time.zone.now - tz} for member ##{member.id}"
        end
      end
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
      Member.find_in_batches(:conditions => [" date(bill_date) = ? ", Date.today + 7.days ]) do |group|
        group.each do |member| 
          tz = Time.zone.now
          begin
            Rails.logger.info "  * processing member ##{member.uuid}"
            member.send_pre_bill
          rescue Exception => e
            Airbrake.notify(:error_class => "Billing::SendPrebill", :error_message => "#{e.to_s}\n\n#{$@[0..9] * "\n\t"}")
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
  desc "Cancel members"
  # This task should be run each day at 3 am ?
  task :cancel => :environment do
    tall = Time.zone.now
    begin
      base =  Member.where(" date(cancel_date) <= ? AND status != ? ", Date.today, 'lapsed')
      Rails.logger.info " *** Starting members:cancel rake task, processing #{base.count} members"
      base.find_in_batches do |group|
        group.each do |member| 
          tz = Time.zone.now
          begin
            Rails.logger.info "  * processing member ##{member.uuid}"
            member.set_as_canceled!
          rescue Exception => e
            Airbrake.notify(:error_class => "Members::Cancel", :error_message => "#{e.to_s}\n\n#{$@[0..9] * "\n\t"}")
            Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
          end
          Rails.logger.info "    ... took #{Time.zone.now - tz} for member ##{member.id}"
        end
      end
    ensure
      Rails.logger.info "It all took #{Time.zone.now - tall}"
    end
  end

  desc "Send Happy birthday email to members"
  # This task should be run each day at 3 am ?
  task :send_happy_birthday => :environment do
    tall = Time.zone.now
    # TODO: this taks must run from a desnormalized database.
    return 
    begin
      base =  Member.where(" birthday = ? and status IS NOT IN (?) ", Date.today, [ 'lapsed', 'applied' ])
      Rails.logger.info " *** Starting members:cancel rake task, processing #{base.count} members"
      base.find_in_batches do |group|
        group.each do |member| 
          tz = Time.zone.now
          begin
            Rails.logger.info "  * processing member ##{member.uuid}"
            Communication.deliver!(:birthday, member)
          rescue Exception => e
            Airbrake.notify(:error_class => "Members::Cancel", :error_message => "#{e.to_s}\n\n#{$@[0..9] * "\n\t"}")
            Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
          end
          Rails.logger.info "    ... took #{Time.zone.now - tz} for member ##{member.id}"
        end
      end
    ensure
      Rails.logger.info "It all took #{Time.zone.now - tall}"
    end
  end


  desc "Send pillar emails"
  task :send_pillar_emails => :environment do 
    tall = Time.zone.now
    begin
      EmailTemplate.find_in_batches(:conditions => " template_type = 'pillar' ") do |group|
        group.each do |template| 
          tz = Time.zone.now
          begin
            Rails.logger.info "  * processing template ##{template.id}"
            Member.find_in_batches(:conditions => 
                [ " join_date = ? AND terms_of_membership_id = ? ", Date.today - template.days_after_join_date.days, 
                  template.terms_of_membership_id ]) do |group1|
              group1.each do |member| 
                tz = Time.zone.now
                begin
                  Rails.logger.info "  * processing member ##{member.uuid}"
                  Communication.deliver!(template, member)
                rescue Exception => e
                  Airbrake.notify(:error_class => "Billing::SendPrebill", :error_message => "#{e.to_s}\n\n#{$@[0..9] * "\n\t"}")
                  Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
                end
                Rails.logger.info "    ... took #{Time.zone.now - tz} for member ##{member.id}"
              end
            end
          rescue Exception => e
            Airbrake.notify(:error_class => "Member::SendPillar", :error_message => "#{e.to_s}\n\n#{$@[0..9] * "\n\t"}")
            Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
          end
          Rails.logger.info "    ... took #{Time.zone.now - tz} for member ##{member.id}"
        end
      end
    ensure
      Rails.logger.info "It all took #{Time.zone.now - tall}"
    end
  end

  desc "Process fulfillments"
  # This task should be run each day at 3 am 
  task :process_fulfillments => :environment do
    tall = Time.zone.now
    begin
      Fulfillment.find_in_batches(:conditions => [" date(renewable_at) <= ? and status = ? ", Date.today, 'open' ]) do |group|
        group.each do |fulfillment| 
          tz = Time.zone.now
          begin
            Rails.logger.info "  * processing member ##{fulfillment.member.uuid} fulfillment ##{fulfillment.id}"
            fulfillment.renew
          rescue Exception => e
            Airbrake.notify(:error_class => "Member::Fulfillment", :error_message => "#{e.to_s}\n\n#{$@[0..9] * "\n\t"}")
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
