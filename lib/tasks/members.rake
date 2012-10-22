namespace :billing do
  desc "Find members that have NBD for today. and bill them all!"
  # This task should be run each day at 3 am ?
  task :for_today => :environment do
    tall = Time.zone.now
    begin
      Member.find_in_batches(:conditions => [" date(next_retry_bill_date) <= ? ", Time.zone.now.to_date]) do |group|
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
      Member.find_in_batches(:conditions => [" date(bill_date) = ? ", Time.zone.now.to_date + 7.days ]) do |group|
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
            error_message: "#{e.to_s}\n\n#{$@[0..9] * "\n\t"}"
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
      base =  Membership.where(" date(cancel_date) <= ? AND status != ? ", Time.zone.now.to_date, 'lapsed')
      Rails.logger.info " *** Starting members:cancel rake task, processing #{base.count} members"
      base.find_in_batches do |group|
        group.each do |membership| 
          tz = Time.zone.now
          begin
            Rails.logger.info "  * processing member ##{membership.member_id}"
            membership.member.set_as_canceled!
          rescue Exception => e
            Airbrake.notify(:error_class => "Members::Cancel", :error_message => "#{e.to_s}\n\n#{$@[0..9] * "\n\t"}")
            Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
          end
          Rails.logger.info "    ... took #{Time.zone.now - tz} for member ##{membership.member_id}"
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
    begin
      base = Member.where(" birth_date = ? and status IN (?) ", Time.zone.now.to_date, [ 'active', 'provisional' ])
      Rails.logger.info " *** Starting members:send_happy_birthday rake task, processing #{base.count} members"
      base.find_in_batches do |group|
        group.each do |member| 
          tz = Time.zone.now
          begin
            Rails.logger.info "  * processing member ##{member.uuid}"
            Communication.deliver!(:birthday, member)
          rescue Exception => e
            Airbrake.notify(:error_class => "Members::send_happy_birthday", :error_message => "#{e.to_s}\n\n#{$@[0..9] * "\n\t"}")
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
      # TODO: join EmailTemplate and Member querys
      EmailTemplate.find_in_batches(:conditions => " template_type = 'pillar' ") do |group|
        group.each do |template| 
          tz = Time.zone.now
          begin
            Rails.logger.info "  * processing template ##{template.id}"
            Membership.find_in_batches(:conditions => 
                [ " join_date = ? AND terms_of_membership_id = ? AND status = 'active' ", 
                  Time.zone.now.to_date - template.days_after_join_date.days, 
                  template.terms_of_membership_id ]) do |group1|
              group1.each do |membership| 
                begin
                  Rails.logger.info "  * processing member ##{membership.member_id}"
                  Communication.deliver!(template, membership.member)
                rescue Exception => e
                  Airbrake.notify(:error_class => "Members::SendPrebill", :error_message => "#{e.to_s}\n\n#{$@[0..9] * "\n\t"}")
                  Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
                end
              end
            end
          rescue Exception => e
            Airbrake.notify(:error_class => "Members::SendPillar", :error_message => "#{e.to_s}\n\n#{$@[0..9] * "\n\t"}")
            Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
          end
          Rails.logger.info "    ... took #{Time.zone.now - tz} for template ##{template.id}"
        end
      end
    ensure
      Rails.logger.info "It all took #{Time.zone.now - tall}"
    end
  end

  desc "Set cc_type on each active credit card."
  task :update_cc_type => :environment do 
    tall = Time.zone.now
    begin
      CreditCard.find_in_batches(:conditions => " cc_type IS NULL and active = true ") do |group|
        group.each do |credit_card| 
          tz = Time.zone.now
          begin
            unless credit_card.member.nil?
              am = credit_card.am_card
              if am.valid?
                credit_card.cc_type = am.type
              else
                credit_card.cc_type = 'unknown'
              end
              credit_card.save
            end
          rescue Exception => e
            Airbrake.notify(:error_class => "Members::CreditCard", :error_message => "#{e.to_s}\n\n#{$@[0..9] * "\n\t"}")
            Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
          end
          Rails.logger.info "    ... took #{Time.zone.now - tz} for credit_card ##{credit_card.id}"
        end
      end
    ensure
      Rails.logger.info "It all took #{Time.zone.now - tall}"
    end
  end

  desc "Process club cash"
  # This task should be run each day at 3 am 
  task :process_club_cash => :environment do
    tall = Time.zone.now
    begin
      Member.find_in_batches(:conditions => [" date(club_cash_expire_date) <= ? ", Time.zone.now.to_date ]) do |group|
        group.each do |member| 
          tz = Time.zone.now
          begin
            Rails.logger.info "  * processing member ##{member.uuid}"
            member.reset_club_cash
          rescue Exception => e
            Airbrake.notify(:error_class => "Member::ClubCash", :error_message => "#{e.to_s}\n\n#{$@[0..9] * "\n\t"}")
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
      Fulfillment.to_be_renewed.find_in_batches do |group|
        group.each do |fulfillment| 
          begin
            Rails.logger.info "  * processing member ##{fulfillment.member_id} fulfillment ##{fulfillment.id}"
            fulfillment.renew!
          rescue Exception => e
            Airbrake.notify(:error_class => "Member::Fulfillment", :error_message => "#{e.to_s}\n\n#{$@[0..9] * "\n\t"}")
            Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
          end
        end
      end
    ensure
      Rails.logger.info "It all took #{Time.zone.now - tall}"
    end
  end
end
