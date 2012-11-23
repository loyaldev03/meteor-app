namespace :billing do
  desc "Find members that have NBD for today. and bill them all!"
  # This task should be run each day at 3 am ?
  task :for_today => :environment do
    tall = Time.zone.now
    begin
      Member.joins(:club).find_in_batches(:conditions => [" date(next_retry_bill_date) <= ? AND clubs.billing_enable = true",
Time.zone.now.to_date]) do |group|
        group.each do |member| 
          tz = Time.zone.now
          begin
            Rails.logger.info "  * processing member ##{member.uuid}"
            member.bill_membership
          rescue Exception => e
            Airbrake.notify(:error_class => "Billing::Today", :error_message => "#{e.to_s}\n\n#{$@[0..9] * "\n\t"}", :parameters => { :member => member.inspect })
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
      base =  Member.joins(:current_membership).where(" date(memberships.cancel_date) <= ? AND memberships.status != ? ", Time.zone.now.to_date, 'lapsed')
      Rails.logger.info " *** Starting members:cancel rake task, processing #{base.count} members"
      base.find_in_batches do |group|
        group.each do |member| 
          tz = Time.zone.now
          begin
            Rails.logger.info "  * processing member ##{member.id}"
            Member.find(member.id).set_as_canceled!
          rescue Exception => e
            Airbrake.notify(:error_class => "Members::Cancel", :error_message => "#{e.to_s}\n\n#{$@[0..9] * "\n\t"}", :parameters => { :member => member.inspect })
            Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
          end
          Rails.logger.info "    ... took #{Time.zone.now - tz} for member ##{member.id}"
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
            Airbrake.notify(:error_class => "Members::CreditCard", :error_message => "#{e.to_s}\n\n#{$@[0..9] * "\n\t"}", :parameters => { :credit_card => credit_card.inspect })
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
            Airbrake.notify(:error_class => "Member::ClubCash", :error_message => "#{e.to_s}\n\n#{$@[0..9] * "\n\t"}", :parameters => { :member => member.inspect })
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
            Airbrake.notify(:error_class => "Member::Fulfillment", :error_message => "#{e.to_s}\n\n#{$@[0..9] * "\n\t"}", :parameters => { :fulfillment => fulfillment.inspect })
            Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
          end
        end
      end
    ensure
      Rails.logger.info "It all took #{Time.zone.now - tall}"
    end
  end
end
