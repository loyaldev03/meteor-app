#!/bin/ruby

require 'import_models'

puts "Step done"
return

@log = Logger.new('log/import_members.log', 10, 1024000)
ActiveRecord::Base.logger = @log

mode = "production"
site_id = SITE_ID

pgc = PaymentGatewayConfiguration.new :login => "s", :merchant_key => "SAC, Inc", 
  :password => "s", :mode => mode, :gateway => "litle", :report_group => "SAC_PRODUCTION"
pgc.club_id = CLUB
pgc.save!

pgc = PaymentGatewayConfiguration.new :login => "94100010879200000001", :merchant_key => "SAC, Inc", 
  :password => "SjVFXAYZtUeejfMQnJDblkEEvqkLUvgU", :mode => mode, :gateway => "mes", :report_group => "SAC_PRODUCTION"
pgc.club_id = CLUB
pgc.save!



# ["Description of TOM,Name of TOM,Grace Period,Term,Needs Approval,Membership amounts,Provisional Days,Club ID,TOM REFERENCE"]
@terms_of_memberships = [
  ["Complimentary Membership","Complimentary Membership","0","Complimentary","No","0","0","ONMC","1"],
  ["Monthly $4.99 Membership", "Monthly $4.99","0","Monthly","No","4.99","30","ONMC","2"],
  ["Monthly $5.95 Membership","Monthly $5.95","0","Monthly","No","5.95","30","ONMC","3"],
  ["Monthly $9.95 Membership","Monthly $9.95","0","Monthly","No","9.95","30","ONMC","4"],
  ["Monthly $14.95 Membership","Monthly $14.95","0","Monthly","No","14.95","30","ONMC","5"],
  ["Annual $20 Membership","Annual $20","0","Annual","No","20","30","ONMC","6"],
  ["Annual $34.95 Membership","Annual $34.95","0","Annual","No","34.95","30","ONMC","7"],
  ["Annual $40.00 Membership","Annual $40.00","0","Annual","No","40","30","ONMC","8"],
  ["Annual $42.00 Membership","Annual $42.00","0","Annual","No","42","30","ONMC","9"],
  ["Annual $44.00 Membership","Annual $44.00","0","Annual","No","44","30","ONMC","10"],
  ["Annual $49.95 Membership","Annual $49.95","0","Annual","No","49.95","30","ONMC","11"],
  ["Annual $54.95 Membership","Annual $54.95","0","Annual","No","54.95","30","ONMC","12"],
  ["Annual $59.95 Membership","Annual $59.95","0","Annual","No","59.95","30","ONMC","13"],
  ["Annual $63.00 LivingSocial Membership","Annual $63.00 LivingSocial","0","Annual","No","63","30","ONMC","14"],
  ["Annual $64.00 Membership","Annual $64.00","0","Annual","No","64","30","ONMC","15"],
  ["Annual $74.00 Membership","Annual $74.00","0","Annual","No","74","30","ONMC","16"],
  ["Annual $84.00 Membership","Annual $84.00","0","Annual","No","84","30","ONMC","17"],
  ["Annual $99.99 Membership","Annual $99.99","0","Annual","No","99.99","30","ONMC","18"],
  ["Annual Join Now $84 Membership","Join Now $84","0","Annual","No","84","0","ONMC","19"],
  ["Annual Join Now $59 Membership","Join Now $59","0","Annual","No","59","0","ONMC","20"],
  ["Annual Join Now $42 Membership","Join Now $42","0","Annual","No","42","0","ONMC","21"]
]

@terms_of_memberships.each do |description, name, grace, term, approval, amount, provisional, club, internal_tom_id|

  tom = TermsOfMembership.new :installment_amount => amount, :description => description, :name => name,  :mode => mode, 
    :needs_enrollment_approval => false, :grace_period => 0, :club_cash_amount => 150
  tom.installment_type = (term == 'Annual' ? '1.year' : ( term == 'Monthly' ? '1.month' : '1000.years' ))
  tom.quota = (term == 'Annual' ? '12' : ( term == 'Monthly' ? '1' : '12000' ))
  tom.club_id = CLUB
  tom.provisional_days = provisional
  tom.save!

  unless internal_tom_id.to_i == 1
    et = EmailTemplate.find_or_create_by_template_type_and_terms_of_membership_id(:cancellation, tom.id)
    et.client = :lyris
    et.name = "Cancellation Email"
    et.external_attributes = { :trigger_id => 6424, :mlid => 47386, :site_id => site_id } 
    et.save

    et = EmailTemplate.find_or_create_by_template_type_and_terms_of_membership_id(:prebill, tom.id)
    et.client = :lyris
    et.name = "Prebill Email"
    et.external_attributes = { :trigger_id => 6426, :mlid => 47623, :site_id => site_id } 
    et.save

    et = EmailTemplate.find_or_create_by_template_type_and_terms_of_membership_id(:refund, tom.id)
    et.client = :lyris
    et.name = "Refund Email"
    et.external_attributes = { :trigger_id => 19144, :mlid => 47386, :site_id => site_id } 
    et.save

    et = EmailTemplate.find_or_create_by_template_type_and_terms_of_membership_id(:hard_decline, tom.id)
    et.client = :lyris
    et.name = "Hard Decline Email"
    et.external_attributes = { :trigger_id => 28511, :mlid => 47386, :site_id => site_id } 
    et.save

    et = EmailTemplate.find_or_create_by_template_type_and_terms_of_membership_id(:soft_decline, tom.id)
    et.client = :lyris
    et.name = "Soft Decline Email"
    et.external_attributes = { :trigger_id => 28512, :mlid => 47386, :site_id => site_id } 
    et.save

    et = EmailTemplate.find_or_create_by_template_type_and_terms_of_membership_id(:birthday, tom.id)
    et.client = :lyris
    et.name = "Birthday Email"
    et.external_attributes = { :trigger_id => 6434, :mlid => 7528, :site_id => site_id } 
    et.save



    # pillar emails
    et = EmailTemplate.new :name => "Deals & Discounts - Pillar Email", :client => :lyris
    et.terms_of_membership_id = tom.id
    et.template_type = :pillar
    et.external_attributes = { :trigger_id => 6418, :mlid => 47386, :site_id => site_id }
    if [6,7,8,9,10,11,12,13,14,15,16,17,18].include?(internal_tom_id.to_i)
      et.days = 35
    else
      et.days = 3
    end
    et.save!


    et = EmailTemplate.new :name => "Content - Pillar Email", :client => :lyris
    et.terms_of_membership_id = tom.id
    et.template_type = :pillar
    et.external_attributes = { :trigger_id => 6419, :mlid => 47386, :site_id => site_id }
    if [6,7,8,9,10,11,12,13,14,15,16,17,18].include?(internal_tom_id.to_i)
      et.days = 40
    else
      et.days = 7
    end
    et.save!

    et = EmailTemplate.new :name => "VIP - Pillar Email", :client => :lyris
    et.terms_of_membership_id = tom.id
    et.template_type = :pillar
    et.external_attributes = { :trigger_id => 6420, :mlid => 47386, :site_id => site_id }
    if [6,7,8,9,10,11,12,13,14,15,16,17,18].include?(internal_tom_id.to_i)
      et.days = 45
    else
      et.days = 11
    end
    et.save!

    et = EmailTemplate.new :name => "Local Chapters - Pillar Email", :client => :lyris
    et.terms_of_membership_id = tom.id
    et.template_type = :pillar
    et.external_attributes = { :trigger_id => 6421, :mlid => 47386, :site_id => site_id }
    if [6,7,8,9,10,11,12,13,14,15,16,17,18].include?(internal_tom_id.to_i)
      et.days = 50
    else
      et.days = 15
    end
    et.save!

    et = EmailTemplate.new :name => "Trial Comm", :client => :lyris
    et.terms_of_membership_id = tom.id
    et.template_type = :pillar
    et.external_attributes = { :trigger_id => 6417, :mlid => 47386, :site_id => site_id }
    if [6,7,8,9,10,11,12,13,14,15,16,17,18].include?(internal_tom_id.to_i)
      et.days = 7
    else
      et.days = 19
    end
    et.save!

  end
end
