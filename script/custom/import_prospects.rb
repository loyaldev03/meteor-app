#!/bin/ruby

require_relative 'import_models'

@log = Logger.new('import_prospects.log', 10, 1024000)
ActiveRecord::Base.logger = @log

@cids = %w(
1468
1469
1548
1549
1550
1551
1552
1553
1554
1555
1556
1557
1558
1559
1560
1561
1562
1563
1564
1565
1566
1567
1568
1569
1570
1571
1572
1573
1574
1575
1576
1577
1578
1579
1580
1581
1582
1583
1584
1585
1586
1587
1588
1589
1590
1591
1592
1593
1594
1595
1596
1597
1598
1599
1600
1601
1602
1603
1604
1605
1606
1607
1677

)


ProspectProspect.where("imported_at IS NULL and campaign_id IN (#{@cids.join(',')}) ").find_in_batches do |group|
  group.each do |prospect| 
    tz = Time.now.utc
    @log.info "  * processing prospect ##{prospect.id}"
    begin
      campaign = BillingCampaign.find_by_id(prospect.campaign_id)
      if campaign.nil? or campaign.phoenix_tom_id.nil?
        tom_id = get_terms_of_membership_id(prospect.campaign_id)
      else
        tom_id = campaign.phoenix_tom_id
      end
      if tom_id.nil?
        puts "CDId #{prospect.campaign_id} does not exist or TOM is empty"
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
      phoenix.joint = campaign.is_joint
      phoenix.marketing_code = campaign.marketing_code
      phoenix.terms_of_membership_id = tom_id
      phoenix.referral_host = campaign.referral_host
      phoenix.landing_url = campaign.landing_url
      phoenix.mega_channel = campaign.phoenix_mega_channel
      phoenix.product_sku = campaign.product_sku
      phoenix.save!
      prospect.update_attribute :imported_at, Time.now.utc
      print "."
    rescue Exception => e
      @log.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
      puts "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
      exit
    end
    @log.info "    ... took #{Time.now.utc - tz} for prospect ##{prospect.id}"
  end
end
