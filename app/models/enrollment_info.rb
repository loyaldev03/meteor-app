class EnrollmentInfo < ActiveRecord::Base

  belongs_to :member
  belongs_to :prospect

  attr_accessible :member_id, :prospect_id, :enrollment_amount, :product_sku, :product_description, :mega_channel,
                  :marketing_code, :fulfillment_code, :ip_address, :user_agent, :referral_host,
                  :referral_parameters, :referral_path, :user_id, :landing_url, :terms_of_membership_id,
                  :preferences, :cookie_value, :cookie_set, :campaign_medium, :campaign_description,
                  :campaign_medium_version, :is_joint

  # Id of the member the enrollment info is related to. (It is setted after creating the member)
  attr_reader :member_id

  # Id of the prospect the enrollment info is related to.
  attr_reader :prospect_id

  # Amount of money that takes to enroll or recover. 
  attr_reader :enrollment_amount

  # Name of the selected product.
  attr_reader :product_sku

  # Description of the selected product.
  attr_reader :product_description

  # multi-team
  attr_reader :marketing_code

  # Id of the fulfillment we are sending to our member. (car-flag).
  attr_reader :fulfillment_code

  # Ip address from where the enrollment is being submitted.
  attr_reader :ip_address

  # Information related to the browser and computer from where the enrollment is being submitted.
  attr_reader :user_agent

  # Link where is being redirect when after subimiting the enroll. (It shows the params in it),
  attr_reader :referral_host

  attr_reader :user_id

  # Url from where te submit comes from.
  attr_reader :landing_url

  # Id of the temr of memebership related to the member.
  attr_reader :terms_of_membership_id

  # Information about the preferences selected when enrolling. This will be use to know about the member likes.
  attr_reader :preferences 

  # Cookie from where the enrollment is being submitted.
  attr_reader :cookie_value

  # If the cookie_value is being recieved or not. It also inform is the client has setted a cookie on his side.
  attr_reader :cookie_set

  attr_reader :campaign_medium

  # The name of the campaign.
  attr_reader :campaign_description

  # Rule: Every time there is a new banner for a specific combination of Mega channel, medium, source and landing page, that banner will be assigned the content number of 1. Each banner version after that will receive its respective number. To check the existing banners use the following document: https://docs.google.com/spreadsheet/ccc?key=0AvZgNVTJtbcUdFBZdWZ5YW01ZnlDTWY0U3Z6NzY4cnc 
  attr_reader :campaign_medium_version

  attr_reader :is_joint
end