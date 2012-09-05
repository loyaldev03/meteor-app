#!/bin/ruby

require 'import_models'

@log = Logger.new('import_prospects.log', 10, 1024000)
ActiveRecord::Base.logger = @log

@cids.each do |cid|
  @campaign = BillingCampaign.find_by_id(cid)
  return if @campaign.nil?

  if @campaign.phoenix_tom_id.nil?
    tom_id = get_terms_of_membership_id(cid)
    @campaign = BillingCampaign.find_by_id(cid)
  else
    tom_id = @campaign.phoenix_tom_id
  end
  if tom_id.nil?
    puts "CDId #{cid} does not exist or TOM is empty"
    next
  end
  tom = PhoenixTermsOfMembership.find(tom_id)

  #ProspectProspect.where(" imported_at IS NULL and campaign_id = #{cid} AND phone REGEXP '^[a-zA-Z]{4,}' ").find_in_batches do |group|
  ProspectProspect.where(" imported_at IS NULL and campaign_id = #{cid} ").find_in_batches do |group|
    puts "cant #{group.count}"
    group.each do |prospect| 
      tz = Time.now.utc
      @log.info "  * processing prospect ##{prospect.id}"
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
        phoenix.email = prospect.email_to_import
        phoenix.phone_number = prospect.phone
        phoenix.created_at = prospect.created_at
        phoenix.updated_at = prospect.created_at # It has a reason. updated_at was modified by us ^^
        phoenix.birth_date = prospect.birth_date
        phoenix.joint = @campaign.is_joint
        phoenix.marketing_code = @campaign.marketing_code
        phoenix.terms_of_membership_id = tom_id
        phoenix.referral_host = @campaign.referral_host
        phoenix.landing_url = @campaign.landing_url
        phoenix.mega_channel = @campaign.phoenix_mega_channel
        phoenix.product_sku = @campaign.product_sku
        phoenix.fulfillment_code = @campaign.fulfillment_code
        phoenix.product_description = @campaign.product_description
        phoenix.campaign_medium = @campaign.campaign_medium
        phoenix.campaign_description = @campaign.campaign_description
        phoenix.campaign_medium_version = @campaign.campaign_medium_version

        today = phoenix.created_at
        phoenix.cohort = [ today.in_time_zone(TIMEZONE).year.to_s, 
          "%02d" % today.in_time_zone(TIMEZONE).month.to_s, 
          phoenix.mega_channel.to_s.strip, 
          phoenix.campaign_medium.to_s.strip, tom.installment_type ].join('-').downcase

        # TODO: 
        # phoenix.preferences = { :fav_driver => prospect.fav_driver }
        # phoenix.gender = @campaign.product_sku
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
end

