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
      Member.find_in_batches( :conditions => ("sync_status IN ('with_error', 'not_synced')") ) do |group|
        group.each do |member|
          Rails.logger.info "  * processing member ##{member.uuid}"
          api_m = member.api_member
          if api_m.save!(force: true)
            unless member.last_sync_error_at
              Auditory.audit(nil, "Member synchronized by batch script", message, member)
            end
          end
        end
      end
    ensure 
      Rails.logger.info "It all took #{Time.zone.now - tall}"
    end
  end

  desc "Process members with duplicated emails errors on sync"
  # This task should be run every X hours. 
  task :process_email_sync_error => :environment do
    begin
      member_list = []
      Member.find_in_batches( :conditions => ("sync_status = 'with_error' AND last_sync_error like 'The e-mail address%is already taken.%'") ) do |group|
        group.each do |member|
          member_list << member
        end
      end  
      Notifier.members_with_duplicated_email_sync_error(member_list).deliver!
    end 
  end
end


"The e-mail address <em class=\"placeholder\">testemail@mailinator.com</em> is already taken."
