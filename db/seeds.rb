# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

data = 'test@test.com.ar'
u = Agent.new :email => data, :username => data, :password => data, :password_confirmation => data
u.save!

u.confirm!

p = Partner.new :prefix => 'NFL', :name => 'NFL'
p.save!

c = Club.new :partner_id => p.id, :name => "Fans"
c.save!
c2 = Club.new :partner_id => p.id, :name => "Players"
c2.save!

d = Domain.new :url => "http://test.com.ar/", :partner => p, :club_id => c.id
d.save!
d = Domain.new :url => "http://test2.com.ar/", :partner => p, :club_id => c2.id
d.save!

pgc = PaymentGatewayConfiguration.new :login => "0000000", :merchant_key => "key", :password => "234", :mode => "development", :gateway => "mes", :club => c
pgc.save!

pgc = PaymentGatewayConfiguration.new :login => "0000000", :merchant_key => "key", :password => "234", :mode => "development", :gateway => "mes", :club => c2
pgc.save!


tom = TermsOfMembership.new :club => c, :installment_amount => 34.56, :installment_type => "30.days", :needs_enrollment_approval => false
tom.save!
tom = TermsOfMembership.new :club => c2, :installment_amount => 45, :installment_type => "30.days", :needs_enrollment_approval => false
tom.save!
