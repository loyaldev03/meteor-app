#!/bin/ruby

require_relative 'import_models'

ProspectProspect.where("imported_at IS NULL").find_in_batches do |group|
  group.each do |prospect| 
    tz = Time.now.utc
    @log.info "  * processing prospect ##{prospect.id}"
    PhoenixProspect.transaction do 
      begin
        phoenix = PhoenixProspect.new 
        phoenix.club_id = CLUB
        phoenix.first_name = prospect.first_name
        phoenix.last_name = prospect.last_name
        phoenix.address = prospect.address
        phoenix.city = prospect.city
        phoenix.state = prospect.state
        phoenix.zip = prospect.zip
        phoenix.country = prospect.country
        phoenix.email = (TEST ? "test#{prospect.id}@xagax.com" : prospect.email)
        phoenix.phone_number = prospect.phone
        phoenix.created_at = prospect.created_at
        phoenix.updated_at = prospect.updated_at
        phoenix.birth_date = prospect.birth_date
        phoenix.joint = prospect.joint
        phoenix.reporting_code = prospect.reporting_code
        phoenix.terms_of_membership_id = get_terms_of_membership_id(prospect.campaign_id)
        phoenix.preferences = { :mega_channel => prospect.mega_channel, :product_id => prospect.product_id }
        phoenix.save!
        prospect.update_attribute :imported_at, Time.now.utc
      rescue Exception => e
        @log.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
        puts "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
        exit
        raise ActiveRecord::Rollback
      end
    end
    @log.info "    ... took #{Time.now.utc - tz} for prospect ##{prospect.id}"
  end
  sleep(5) # Make sure it doesn't get too crowded in there!
end
