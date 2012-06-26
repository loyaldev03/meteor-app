#!/bin/ruby

require_relative 'import_models'

# "Email Name ","MLID","Trigger ID","Corresponding Event Name","Recurring","Before or After","Day","Notes"

annual_sloop = [
  [ "Welcome E-mail SLOOP",47386,6411,"Join","no","After",0,],
  [ "Activation E-mail",47386,9400,,"no",,,"Are we doing this one?"],
  [ "Trial Comm-Day 7",47386,6417,"Join","no","After",7,],
  [ "Pre Bill",47623,6426,"NBD","yes","Before",7,],
  [ "Pillar 1 - Deals & Discounts",47386,6418,"Join","no","After",35,],
  [ "Pillar 2 - Content",47386,6419,"Join","no","After",40,],
  [ "Pillar 3 - VIP",47386,6420,"Join","no","After",45,],
  [ "Pillar 4 - Local",47386,6421,"Join","no","After",50,],
  [ "Cancellation",47386,6424,"Cancel","no","After",0,],
  [ "Cancel with Refund ",47386,19144,"Refund","no","After",0,],
  [ "Renewal Pre Bill",47623,6427,"NBD; Member > 350 days","yes","Before",7,],
  [ "ONMC Newsletter - Annual Activated",116804,"-","Every Thursday","yes",,,"Sending manually currently"],
  [ "ONMC Newsletter - Annual Not Activated",116804,"-","Every Thursday","yes",,,"Sending manually currently"],
  [ "Forgot Password - Customer Service Initiated",9398,183590,"?","no","After",0,],
  [ "Forgot Password - Member Initiated at ONMC.COM",9399,183590,"?","no","After",0,],
  [ "Active Member Birthday E-mail",6434,47528,"?","yes","After","Platform: Birthday", ],
  [ "Local Chapter Newsletter",116804,"-","Monthly - 2nd Tuesday","yes",,,"Sending manually currently" ]
]

# rename 'Renewal Pre Bill" =>  to "Pre Bill" only on this csv
annual_join_now = [
  [ "Welcome E-mail SLOOP",47386,6411,"Join","no","After",0,
  [ "Welcome E-mail Canadians",47386,6412,"Join","no","After",0,"Not doing currently; wouldn't mind testing it again" ],
  [ "Activation E-mail",47386,9400,,"no",,,"Are we doing this one?" ],
  [ "Pillar 1 - Deals & Discounts",47386,6418,"Join","no","After",2,],
  [ "Pillar 2 - Content",47386,6419,"Join","no","After",4,],
  [ "Pillar 3 - VIP",47386,6420,"Join","no","After",6,],
  [ "Pillar 4 - Local",47386,6421,"Join","no","After",8,],
  [ "Cancellation",47386,6424,"Cancel","no","After",0,],
  [ "Cancel with Refund ",47386,19144,"Refund","no","After",0,],
  # [ "Renewal Pre Bill",47623,6427,"NBD; Member > 350 days","yes","Before",7,],
  [ "Pre Bill",47623,6427,"NBD; Member > 350 days","yes","Before",7,],
  [ "ONMC Newsletter - Annual Activated",116804,"-","Every Thursday","yes",,,"Sending manually currently"],
  [ "ONMC Newsletter - Annual Not Activated",116804,"-","Every Thursday","yes",,,"Sending manually currently"],
  [ "Forgot Password - Customer Service Initiated",9398,183590,"?","no","After",0,],
  [ "Forgot Password - Member Initiated at ONMC.COM",9399,183590,"?","no","After",0,],
  [ "Active Member Birthday E-mail",6434,47528,"?","yes","After","Platform: Birthday",],
  [ "Local Chapter Newsletter",116804,"-","Monthly - 2nd Tuesday","yes",,,"Sending manually currently; NOTE: This is only sent to Local Chapter members"]
]

annual_ptx = [
  [ "Welcome E-mail PTX",47386,6414,"Join","no","After",0, ], 
  [ "Welcome E-mail Canadians",47386,6412,"Join","no","After",0,"Not doing currently; wouldn't mind testing it again"], 
  [ "Activation E-mail",47386,9400,,"no",,,"Are we doing this one?"], 
  [ "Trial Comm-Day 7",47386,6417,"Join","no","After",7,], 
  [ "Pre Bill",47623,6426,"NBD","yes","Before",7,], 
  [ "Pillar 1 - Deals & Discounts",47386,6418,"Join","no","After",35,], 
  [ "Pillar 2 - Content",47386,6419,"Join","no","After",40,], 
  [ "Pillar 3 - VIP",47386,6420,"Join","no","After",45,], 
  [ "Pillar 4 - Local",47386,6421,"Join","no","After",50,], 
  [ "Cancellation",47386,6424,"Cancel","no","After",0,], 
  [ "Cancel with Refund ",47386,19144,"Refund","no","After",0,], 
  [ "Renewal Pre Bill",47623,6427,"NBD; Member > 350 days","yes","Before",7,], 
  [ "ONMC Newsletter - Annual Activated",116804,"-","Every Thursday","yes",,,"Sending manually currently"], 
  [ "ONMC Newsletter - Annual Not Activated",116804,"-","Every Thursday","yes",,,"Sending manually currently"], 
  [ "Forgot Password - Customer Service Initiated",9398,183590,"?","no","After",0,], 
  [ "Forgot Password - Member Initiated at ONMC.COM",9399,183590,"?","no","After",0,], 
  [ "Active Member Birthday E-mail",6434,47528,"?","yes","After","Platform: Birthday",], 
  [ "Local Chapter Newsletter",116804,"-","Monthly - 2nd Tuesday","yes",,,"Sending manually currently"]
]

monthly_sloops = [
  [ "Welcome E-mail SLOOP",47386,6411,"Join","no","After",0,],
  [ "Activation E-mail",47386,9400,,"no",,,"Are we doing this one?"],
  [ "Pillar 1 - Deals & Discounts",47386,6418,"Join","no","After",2,],
  [ "Pillar 2 - Content",47386,6419,"Join","no","After",4,],
  [ "Pillar 3 - VIP",47386,6420,"Join","no","After",6,],
  [ "Pillar 4 - Local",47386,6421,"Join","no","After",8,],
  [ "Pre Bill",47623,6426,"NBD","yes","Before",7,],
  [ "Cancellation",47386,6424,"Cancel","no","After",0,],
  [ "Cancel with Refund ",47386,19144,"Refund","no","After",0,],
  [ "ONMC Newsletter - Monthly Activated",116804,"-","Every Thursday","yes",,,"Sending manually currently"],
  [ "ONMC Newsletter - Monthly Not Activated",116804,"-","Every Thursday","yes",,,"Sending manually currently"],
  [ "Forgot Password - Customer Service Initiated",9398,183590,"?","no","After",0,],
  [ "Forgot Password - Member Initiated at ONMC.COM",9399,183590,"?","no","After",0,],
  [ "Active Member Birthday E-mail",6434,47528,"?","yes","After","Platform: Birthday",],
  [ "Local Chapter Newsletter",116804,"-","Monthly - 2nd Tuesday","yes",,,"Sending manually currently; NOTE: This is only sent to Local Chapter members"]
]

def add_email_template(name, type, tom_id, trigger_id, mlid, site_id, days_after_join_date = 0)
  et = EmailTemplate.new 
  et.name = name
  et.client = :lyris
  et.days_after_join_date = days_after_join_date.to_i
  et.template_type = type
  et.external_attributes = { :trigger_id => trigger_id, :mlid => mlid, :site_id => site_id } 
  et.terms_of_membership_id = tom_id
  et.save
end

# TODO set SITE_ID

# "Email Name ","MLID","Trigger ID","Corresponding Event Name","Recurring","Before or After","Day","Notes"
def upload_email_services(communications, tom_id)
  communications.each do |comm|
    type, days = nil, nil
    if comm[0] == 'Activation E-mail'
      type = :active
    elsif comm[0] == 'Pre Bill'
      type = :prebill
    elsif comm[0] == 'Cancellation'
      type = :cancellation
    elsif comm[0] == 'Cancel with Refund'
      type = :refund
    # we will have prebill renewal on phoenix 1.1
    # elsif comm[0] == 'Renewal Pre Bill'
    #  type = :prebill_renewal
    elsif comm[0].include?('Trial Comm-Day 7')
      type = :pillar
      days = comm[6]
    elsif comm[0].include?('Pillar')
      type = :pillar
      days = comm[6]
    elsif comm[0].include?('Active Member Birthday E-mail')
      type = :birthday
    end
    add_email_template(comm[0], type, tom_id, comm[2], comm[1], SITE_ID, days) unless type.nil?
  end
end

[ { :text => '%Annual%Sloop%', :array => annual_sloop } ].each do |text, array|
  PhoenixTermsOfMembership.where(" name like '#{text}' ").find_in_batches do |group|
    group.each do |tom| 
      upload_email_services(array, tom.id)
    end
  end
end
