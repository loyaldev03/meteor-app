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

c = Club.new :name => "Fans"
c.partner = p
c.save!
c2 = Club.new :name => "Players"
c2.partner = p
c2.save!

d = Domain.new :url => "http://test.com.ar/"
d.club = c
d.partner = p
d.save!
if c.respond_to?(:drupal_domain)
  c.drupal_domain = d
  c.save
end
d = Domain.new :url => "http://test2.com.ar/"
d.partner = p
d.club = c2
d.save!

pgc = PaymentGatewayConfiguration.new :login => "94100010879200000001", 
  :merchant_key => "SAC, Inc", :password => "SjVFXAYZtUeejfMQnJDblkEEvqkLUvgU", 
  :mode => "development", :gateway => "mes", :report_group => "SAC_STAGING_TEST"
pgc.club = c
pgc.save!

pgc = PaymentGatewayConfiguration.new :login => "94100010879200000001", 
  :merchant_key => "SAC, Inc", :password => "SjVFXAYZtUeejfMQnJDblkEEvqkLUvgU", 
  :mode => "development", :gateway => "mes", :report_group => "SAC_STAGING_TEST"
pgc.club = c2
pgc.save!


tom = TermsOfMembership.new :installment_amount => 34.56, :installment_type => "1.month", 
  :needs_enrollment_approval => false, :name => "test2"
tom.club = c
tom.save!
tom = TermsOfMembership.new :installment_amount => 100.56, :installment_type => "1.year", 
  :needs_enrollment_approval => false, :name => "test2-year"
tom.club = c
tom.save!
tom = TermsOfMembership.new :installment_amount => 45, :installment_type => "1.year", 
  :needs_enrollment_approval => false, :name => "test"
tom.club = c2
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