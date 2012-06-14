#!/bin/ruby

require_relative 'import_models'

ProspectProspect.where("imported_at IS NULL").find_in_batches do |group|
  group.each do |prospect| 
    tz = Time.now
    begin
      @log.info "  * processing prospect ##{prospect.id}"
      phoenix = PhoenixProspect.new 
      phoenix.club_id = CLUB
      phoenix.first_name = prospect.first_name
      phoenix.last_name = prospect.last_name
      phoenix.address = prospect.address
      phoenix.city = prospect.city
      phoenix.state = prospect.state
      phoenix.zip = prospect.zip
      # phoenix.country = 'US'
      phoenix.email = prospect.email
      phoenix.email = "test#{prospect.id}@xagax.com"
      phoenix.phone_number = prospect.phone
      phoenix.created_at = prospect.created_at
      phoenix.updated_at = prospect.updated_at
      phoenix.birth_date = prospect.birth_date
      phoenix.joint = prospect.joint
      phoenix.reporting_code = prospect.reporting_code
      phoenix.terms_of_membership_id = get_terms_of_membership_id(prospect.campaign_id)
      phoenix.preferences = { :sport_id => prospect.sport_id, :media_id => prospect.media_id, 
        :favorite_driver => prospect.fav_driver }
      phoenix.save!
      prospect.update_attribute :imported_at, Time.zone.now
    rescue Exception => e
      @log.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
      puts "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
      exit
    end
    @log.info "    ... took #{Time.now - tz} for prospect ##{prospect.id}"
  end
  sleep(5) # Make sure it doesn't get too crowded in there!
end
