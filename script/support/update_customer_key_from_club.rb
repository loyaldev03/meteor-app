
def update_customer_key(id, email_template_name, customer_key)
  club = Club.find id
  # TODO: find the correct object please 
  # 	[Paul: done, the correct object could be obtained as follows: Club.TermsOfMembeships.EmailTemplates,
  # or maybe we can do EmailTemplates.joins(:terms_of_memberships)
  # 																	.joins(:clubs)
  # 																	.where("terms_of_membershps.club_id = #{id}")
  # 																	.where("email_templates.name = '#{email_template_name}').first
  # or something like, but we not have the needed relations defined in the EmailTemplate model. ]

  club.terms_of_memberships.each do |tom|
    et = tom.email_templates.where("name like '#{email_template_name}'").first
    if !et.nil?
      et.external_attributes[:customer_key] = customer_key
      if et.save
        return "OK - [#{email_template_name}]"
      else
        return "Error to update the email template - [#{email_template_name}]"
      end
    end
  end

  return "Not found - [#{email_template_name}]" if et.nil?
	
rescue
  return "club id not found"
end

templates_to_update = [
  ["Thank you for supporting", 634, "Enjoy"],
  ["Provisional Member 8", 632, "Hurry - Don't Miss - Donate/Paid Sub. Benefits"],
  ["Refund Email", 633, "refund"],
  ["Provisional Member 7", 631, "Give/Get - Donation/Follow Your Favorites"],
  ["Provisional Member 6", 630, "Product Engagement - 4 (High School Content)"],
  ["Provisional Member 5", 629, "Product Engagement (Contests. Extra Entries)"],
  ["Provisional Member 4", 628, "Free Trial/Reminder of Benefits"],
  ["Provisional Member 3", 627, "Product Engagement - 2 (1v1)"],
  ["Provisional Member 2", 626, "Product Engagement - 1 (Refer-A-Friend)"],
  ["Pre Bill Email", 625, "Pre Bill"],
  ["Cancellation", 623, "Cancellation Email"],
  ["Hard Decline Email", 624, "Hard Decline"],
  ["(Paid Member) 8", 622, "Prebill Notification (Donate/Paid Sub. Benefits)"],
  ["(Paid Member) 7", 621, "Useful Tip #4 (More Entries)"],
  ["(Paid Member) 6", 620, "Useful Tip #3 (My Hub:Filter)"],
  ["(Paid Member) 5", 619, "Desired Action #2 - Twitter/Facebook"],
  ["(Paid Member) 4",618, "Useful Tip #2 (Follow More Athletes and Teams)"],
  ["(Paid Member) 3", 617, "Useful Tip #1 (1v1)"],
  ["(Paid Member) 2", 616, "Desired Action (Refer-A-Friend)"],
  ["(Free Member) 8", 615, "Incentive Offer -Last Chance"],
  ["(Free Member) 7", 614, "What You're Missing - 4 (Reminder of Benefits)"],
  ["(Free Member) 6", 613, "Testimonials"],
  ["(Free Member) 5", 612, "What You're Missing - 3 (High School Content)"],
  ["(Free Member) 4", 611, "What You're Missing - 2 (Contests, Extra Entries)"],
  ["(Free Member) 3", 610, "Donation/Follow Your Favorites"],
  ["(Free Member) 2", 609, "What you're Missing - 1 (1v1)"],
  ["(Free Member) 1", 608, "New Status - Upsell"]
]

templates_to_update.each do |ett|
  # TODO: replace 3 with the correct club id
  # 	[Paul: the club_id for 'Statzhub' is: 3 ]
  puts update_customer_key(3, ett[2], ett[1])
end
