#!/bin/ruby

require 'import_models'

@log = Logger.new('log/import_prospects.log', 10, 1024000)
ActiveRecord::Base.logger = @log

ProspectProspect.where(" imported_at IS NULL and campaign_id = #{cid} ").find_in_batches do |group|
  puts "cant #{group.count}"
  group.each do |prospect| 
    get_campaign_and_tom_id(member.campaign_id)
    if @tom_id.nil?
      puts "CDId #{member.campaign_id} does not exist or TOM is empty"
      next
    end
    tz = Time.now.utc
    @log.info "  * processing prospect ##{prospect.id}"
    begin
      phoenix = PhoenixProspect.new 
      phoenix.first_name = prospect.first_name
      phoenix.last_name = prospect.last_name
      phoenix.address = prospect.address
      phoenix.city = prospect.city
      phoenix.state = prospect.state
      phoenix.zip = prospect.zip
      phoenix.country = prospect.country
      phoenix.email = prospect.email_to_import
      phoenix.phone_country_code = prospect.phone_country_code
      phoenix.phone_area_code = prospect.phone_area_code
      phoenix.phone_local_number = prospect.phone_local_number
      phoenix.created_at = prospect.created_at
      phoenix.updated_at = prospect.created_at # It has a reason. updated_at was modified by us ^_^
      phoenix.birth_date = prospect.birth_date
      phoenix.joint = @campaign.is_joint
      phoenix.marketing_code = @campaign.marketing_code
      phoenix.terms_of_membership_id = @tom_id
      phoenix.referral_host = @campaign.referral_host
      phoenix.landing_url = @campaign.landing_url
      phoenix.mega_channel = @campaign.phoenix_mega_channel
      phoenix.product_sku = @campaign.product_sku
      phoenix.fulfillment_code = @campaign.fulfillment_code
      phoenix.product_description = @campaign.product_description
      phoenix.campaign_medium = @campaign.campaign_medium
      phoenix.campaign_description = @campaign.campaign_description
      phoenix.campaign_medium_version = @campaign.campaign_medium_version
      phoenix.preferences = { :old_id => prospect.id }.to_json
      phoenix.referral_parameters = {}.to_json
      phoenix.gender = prospect.gender
      phoenix.save!

      prospect.update_attribute :imported_at, Time.now.utc
      print "."
    rescue Exception => e
      @log.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
      puts "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
    end
    @log.info "    ... took #{Time.now.utc - tz} for prospect ##{prospect.id}"
  end
end

