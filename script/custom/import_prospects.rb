#!/bin/ruby

require_relative 'import_models'

ProspectProspect.where("imported_at IS NULL").find_in_batches do |group|
  group.each do |prospect| 
    tz = Time.now.utc
    @log.info "  * processing prospect ##{prospect.id}"
    PhoenixProspect.transaction do 
      begin
        tom_id = get_terms_of_membership_id(prospect.campaign_id)
        if tom_id.nil?
          puts "CDId #{member.campaign_id} does not exist or TOM is empty"
          exit
          next
        end

        phoenix = PhoenixProspect.new 
        phoenix.club_id = CLUB
        phoenix.first_name = prospect.first_name
        phoenix.last_name = prospect.last_name
        phoenix.address = prospect.address
        phoenix.city = prospect.city
        phoenix.state = prospect.state
        phoenix.zip = prospect.zip
        phoenix.country = prospect.country
        phoenix.email = prospect.email_to_import
        phoenix.phone_number = prospect.phone
        phoenix.created_at = prospect.created_at
        phoenix.updated_at = prospect.created_at # It has a reason. updated_at was modified by us ^^
        phoenix.birth_date = prospect.birth_date
        phoenix.joint = prospect.joint
        phoenix.marketing_code = prospect.reporting_code
        phoenix.terms_of_membership_id = tom_id
        phoenix.preferences = { :mega_channel => prospect.mega_channel, :product_id => prospect.product_id }.to_json
        phoenix.save!
        prospect.update_attribute :imported_at, Time.now.utc
      rescue Exception => e
        @log.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
        puts "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
        raise ActiveRecord::Rollback
      end
    end
    @log.info "    ... took #{Time.now.utc - tz} for prospect ##{prospect.id}"
  end
end
