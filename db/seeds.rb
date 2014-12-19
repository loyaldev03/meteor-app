# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

# Clear any existing tables
DeclineStrategy.delete_all!
Agent.delete_all!
Partner.delete_all!
Club.delete_all!
Domain.delete_all!
PaymentGatewayConfiguration.delete_all!
TermsOfMembership.delete_all!
CommunicationType.delete_all!
DispositionType.delete_all!
MemberCancelReason.delete_all!
MemberBlacklistReason.delete_all!


File.open("#{Rails.root}/db/decline_strategies.sql", 'r') do |file|
  while statements = file.gets("") do
    ActiveRecord::Base.connection.execute(statements)
  end
end

data = 'batch@xagax.com'
u = Agent.new :email => data, :username => data, :password => data, :password_confirmation => data
u.save!

data = 'platform@xagax.com'
admin = Agent.new :email => data, 
  :roles    => 'admin',
  :username => 'admin', 
  :password => 'xagax2012', 
  :password_confirmation => 'xagax2012'
admin.save!

data = 'test@test.com.ar'
u = Agent.new :email => data, :username => data, :password => data, :password_confirmation => data, :roles => 'admin'
u.save!

p = Partner.new :prefix => 'NFL', :name => 'NFL'
p.save!
p2 = Partner.new :prefix => 'AO', :name => 'American Outdoorsman', :contract_uri => '/south01/contracts/aoac', :website_url => 'http://aohq.com'
p2.save!
p3 = Partner.new :prefix => 'TC', :name => 'Tennis', :contract_uri => '/tennis', :website_url => 'http://www.tennischanneladvantage.com/'
p3.save!
p4 = Partner.new :prefix => 'ONMC', :name => 'ONMC Import', :contract_uri => '', :website_url => '', :description => 'Partner to test imports from ONMC.'
p4.save!


c = Club.new :name => "Fans", :cs_phone_number => '123-456-7890'
c.partner = p
c.save!
c2 = Club.new :name => "Players", :cs_phone_number => '123-456-7890'
c2.partner = p
c2.save!
c3 = Club.new :name => "TC Fans", :cs_phone_number => '123-456-7890'
c3.partner = p3
c3.save!
c4 = Club.new :name => "TC Players", :cs_phone_number => '123-456-7890'
c4.partner = p3
c4.save!
c5 = Club.new :name => "Nascar", :cs_phone_number => '123-456-7890', :api_type => 'Drupal::Member', :theme => 'application'
c5.partner = p4
c5.save! 
c6 = Club.new :name => "AO Adventure Club", :cs_phone_number => '123-456-7890', :api_type => 'Drupal::Member', :theme => 'application'
c6.partner = p2
c6.save!

d = Domain.new :url => "http://test.com.ar/"
d.club = c
d.partner = p
d.save!
d2 = Domain.new :url => "http://test2.com.ar/"
d2.partner = p
d2.club = c
d2.save!
d3 = Domain.new :url => "http://affinitystop.com/" 
d3.partner = p
d3.club = c4
d3.save!
d4 = Domain.new :url => "http://www.aoadventureclub.com"
d4.partner = p
d4.save!
d5 = Domain.new :url => "http://www.tennischanneladvantage.com/"
d5.partner = p3
d5.save!
d6 = Domain.new :url => "http://www.tennischanneladvantage2.com/"
d6.partner = p3
d6.save!
if c.respond_to?(:api_domain)
  c.api_domain = d
  c.save
end
if c2.respond_to?(:api_domain)
  c2.api_domain = d2
  c2.save
end
if c4.respond_to?(:api_domain)
  c4.api_domain = d3
  c4.save
end

Club.all.each_with_index do |c, i|
  if (i % 2) == 0
    pgc = PaymentGatewayConfiguration.new :login => "94100010879200000001", 
      :merchant_key => "SAC, Inc", :password => "SjVFXAYZtUeejfMQnJDblkEEvqkLUvgU", 
      :gateway => "mes", :report_group => "SAC_STAGING_TEST", 
      :aus_login => '941000108792', :aus_password => "SjVFXAYZtUeejfMQnJDblkEEvqkLUvgU"
    pgc.club = c
    pgc.save!
  else
    pgc = PaymentGatewayConfiguration.new :login => "a", 
      :merchant_key => "SAC, Inc", :password => "a", 
      :gateway => "litle", :report_group => "SAC_STAGING_TEST", 
      :aus_login => '', :aus_password => ""
    pgc.club = c
    pgc.save!
  end

  tom = TermsOfMembership.new :installment_amount => 34.56,
    :needs_enrollment_approval => false, :name => "test2",
    :installment_period => 30, :initial_fee => 0, :trial_period_amount => 0, :is_payment_expected => 1, :subscription_limits => 0, :if_cannot_bill => 'cancel'
  tom.club = c
  tom.save!
  tom = TermsOfMembership.new :installment_amount => 100.56,
    :needs_enrollment_approval => false, :name => "test2 year",
    :installment_period => 365, :initial_fee => 0, :trial_period_amount => 0, :is_payment_expected => 1, :subscription_limits => 0, :if_cannot_bill => 'cancel'
  tom.club = c
  tom.save!
  tom = TermsOfMembership.new :installment_amount => 45,
    :needs_enrollment_approval => false, :name => "test",
    :installment_period => 365, :initial_fee => 0, :trial_period_amount => 0, :is_payment_expected => 1, :subscription_limits => 0, :if_cannot_bill => 'cancel'
  tom.club = c
  tom.save!
  tom = TermsOfMembership.new :installment_amount => 25,
    :needs_enrollment_approval => false, :name => "test paid", :club_cash_installment_amount => 10,
    :installment_period => 30, :initial_fee => 0, :trial_period_amount => 0, :is_payment_expected => 1, :subscription_limits => 0, :if_cannot_bill => 'cancel'
  tom.club = c
  tom.save!
  tom = TermsOfMembership.new :installment_amount => 100,
    :needs_enrollment_approval => false, :name => "test annual",
    :installment_period => 365, :initial_fee => 0, :trial_period_amount => 0, :is_payment_expected => 1, :subscription_limits => 0, :if_cannot_bill => 'cancel'
  tom.club = c
  tom.save!
  tom = TermsOfMembership.new :installment_amount => 50,
    :needs_enrollment_approval => true, :name => "test approval",
    :installment_period => 30, :initial_fee => 0, :trial_period_amount => 0, :is_payment_expected => 1, :subscription_limits => 0, :if_cannot_bill => 'cancel'
  tom.club = c
  tom.save!
  tom = TermsOfMembership.new :installment_amount => 50,
    :needs_enrollment_approval => true, :name => "test anual approval",
    :installment_period => 365, :initial_fee => 0, :trial_period_amount => 0, :is_payment_expected => 1, :subscription_limits => 0, :if_cannot_bill => 'cancel'
  tom.club = c
  tom.save!
  tom = TermsOfMembership.new :installment_amount => 84,
    :needs_enrollment_approval => false, :name => "test for drupal", :provisional_days => 30,
    :installment_period => 30, :initial_fee => 0, :trial_period_amount => 0, :is_payment_expected => 1, :subscription_limits => 0, :if_cannot_bill => 'cancel'
  tom.club = c
  tom.save!
end

[ 'Incoming Call', 'Outbound Call' ,  'Email' ,  'Chat' , 'Other' ].each do |name|
  c = CommunicationType.new
  c.name = name
  c.save
end

[ c.id, c2.id ].each do |id|
  [ 'confirm', 'Website Question', 'technical support', 'Benefits question', 'Pre bill Cancellation', 
    'Post bill cancellation', 'Pre Bill Save', 'Product question', 'Deals and Discounts', 
    'Club cash question', 'VIP non program', 'Local Chapter question' ].each do |name|
    c = DispositionType.new
    c.name = name
    c.club_id = id
    c.save
  end
end

[ 'Didnt know I enrolled' ,  'Cant afford' ,  'Did not use benefits' ,  'Did not want' , 
  'Only wanted product', 'Cant afford now (possible future call back)', 'CHARGEBACK', 'Others' ].each do |name|
  m = MemberCancelReason.new
  m.name = name
  m.save
end

[ 'Spam', 'Inappropriate behaviour' ].each do |name|
  m = MemberBlacklistReason.new
  m.name = name
  m.save
end
