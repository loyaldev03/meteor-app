# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

data = 'batch@xagax.com'
u = Agent.new :email => data, :username => data, :password => data, :password_confirmation => data
u.save!


data = 'test@test.com.ar'
u = Agent.new :email => data, :username => data, :password => data, :password_confirmation => data, :roles => ['admin']
u.save!

p = Partner.new :prefix => 'NFL', :name => 'NFL'
p.save!
p2 = Partner.new :prefix => 'AO', :name => 'American Outdoorsman', :contact_uri => '/south01/contracts/aoac', :website_url => 'http://aohq.com'
p2.save!
p3 = Partner.new :prefix => 'TC', :name => 'Tennis', :contact_uri => '/tennis', :website_url => 'http://www.tennischanneladvantage.com/'
p3.save!
p4 = Partner.new :prefix => 'ONMC', :name => 'ONMC-Import', :contact_uri => '', :website_url => '', :description => 'Partner to test imports from ONMC.'
p4.save!
p5 = Partner.new :prefix => 'pri', :name => 'TEST', :contact_uri => 'www.test.com', :website_url => 'www.test.com', :description => 'Partner to test imports from ONMC.'
p5.save!


c = Club.new :name => "Fans"
c.partner = p
c.save!
c2 = Club.new :name => "Players"
c2.partner = p
c2.save!
c3 = Club.new :name => "Fans"
c3.partner = p3
c3.save!
c4 = Club.new :name => "Players"
c4.partner = p3
c4.save!
c5 = Club.new :name => "Nascar", :api_type => 'Drupal::Member', :theme => 'application'
c5.partner = p4
c5.save! 
c6 = Club.new :name => "AO Adventure Club", :api_type => 'Drupal::Member', :theme => 'application'
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

[c, c2].each do |c|
  pgc = PaymentGatewayConfiguration.new :login => "94100010879200000001", 
    :merchant_key => "SAC, Inc", :password => "SjVFXAYZtUeejfMQnJDblkEEvqkLUvgU", 
    :mode => "development", :gateway => "mes", :report_group => "SAC_STAGING_TEST"
  pgc.club = c
  pgc.save!
  pgc = PaymentGatewayConfiguration.new :login => "94100010879200000001", 
    :merchant_key => "SAC, Inc", :password => "SjVFXAYZtUeejfMQnJDblkEEvqkLUvgU", 
    :mode => "production", :gateway => "mes", :report_group => "SAC_STAGING_TEST"
  pgc.club = c
pgc.save!
end

tom = TermsOfMembership.new :installment_amount => 34.56, :installment_type => "1.month", 
  :needs_enrollment_approval => false, :name => "test2"
tom.club = c
tom.save!
tom = TermsOfMembership.new :installment_amount => 100.56, :installment_type => "1.year", 
  :needs_enrollment_approval => false, :name => "test2 year"
tom.club = c
tom.save!
tom = TermsOfMembership.new :installment_amount => 45, :installment_type => "1.year", 
  :needs_enrollment_approval => false, :name => "test"
tom.club = c2
tom.save!
tom = TermsOfMembership.new :installment_amount => 25, :installment_type => "30.days", 
  :needs_enrollment_approval => false, :name => "test paid", :club_cash_amount => 10
tom.club = c
tom.save!
tom = TermsOfMembership.new :installment_amount => 100, :installment_type => "1.year", 
  :needs_enrollment_approval => false, :name => "test annual"
tom.club = c
tom.save!
tom = TermsOfMembership.new :installment_amount => 50, :installment_type => "30.days", 
  :needs_enrollment_approval => true, :name => "test approval"
tom.club = c
tom.save!
tom = TermsOfMembership.new :installment_amount => 50, :installment_type => "1.year", 
  :needs_enrollment_approval => true, :name => "test anual approval"
tom.club = c
tom.save!
tom = TermsOfMembership.new :installment_amount => 0.0, :installment_type => "30.days", 
  :needs_enrollment_approval => false, :name => "test for drupal", :provisional_days => 30
tom.club = c
tom.save!


[ 'incomming call' ,  'outbound call' ,  'email' ,  'chat' , 'others' ].each do |name|
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

[ 'didnt know I enrolled' ,  'cant afford' ,  'Did not use benefits' ,  'did not want' , 
  'only wanted product', 'cant afford now (possible future call back)', 'CHARGEBACK', 'others' ].each do |name|
  m = MemberCancelReason.new
  m.name = name
  m.save
end

[ 'Spam', 'Inappropriate behaviour' ].each do |name|
  m = MemberBlacklistReason.new
  m.name = name
  m.save
end