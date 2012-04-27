# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

data = 'batch@xagax.com.ar'
u = Agent.new :email => data, :username => data, :password => data, :password_confirmation => data
u.save!


data = 'test@test.com.ar'
u = Agent.new :email => data, :username => data, :password => data, :password_confirmation => data
u.save!
u.confirm!

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
tom = TermsOfMembership.new :installment_amount => 45, :installment_type => "1.year", 
  :needs_enrollment_approval => false, :name => "test"
tom.club = c2
tom.save!
