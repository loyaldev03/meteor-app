# require 'test_helper' 
 
# class MembersTest < ActionController::IntegrationTest
 
#   setup do
#     init_test_setup
#     @admin_agent = FactoryGirl.create(:confirmed_admin_agent)
#     @partner = FactoryGirl.create(:partner)
#     @club = FactoryGirl.create(:simple_club, :partner_id => @partner.id)
#     @terms_of_membership_with_gateway = FactoryGirl.create(:terms_of_membership_with_gateway)
#     sign_in_as(@admin_agent)
#   end

#   test "create member" do
#   	unsaved_member = FactoryGirl.build(:active_member, 
#       :club_id => @club.id, 
#       :terms_of_membership => @terms_of_membership_with_gateway,
#       :created_by => @admin_agent)

#   	visit members_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)

#  		click_on 'New Member'

#   	within("#table_demographic_information") {
# 	  	fill_in 'member[first_name]', :with => unsaved_member.first_name
# 	  	fill_in 'member[last_name]', :with => unsaved_member.last_name
# 	  	fill_in 'member[city]', :with => unsaved_member.city
# 	  	fill_in 'member[address]', :with => unsaved_member.address
# 	  	fill_in 'member[zip]', :with => unsaved_member.zip
# 	  	fill_in 'member[state]', :with => unsaved_member.state
# 	  	select('M', :from => 'member[gender]')
# 	  	select('US', :from => 'member[country]')
# 		}

# 		page.execute_script("window.jQuery('#member_birth_date').next().click()")
# 	  within(".ui-datepicker-calendar") do
# 	  	click_on("1")
# 	  end

# 		within("#table_contact_information") {
# 			fill_in 'member[email]', :with => unsaved_member.email
# 			fill_in 'member[phone_country_code]', :with => unsaved_member.phone_country_code
# 			fill_in 'member[phone_area_code]', :with => unsaved_member.phone_area_code
# 			fill_in 'member[phone_local_number]', :with => unsaved_member.phone_local_number
# 			select('Home', :from => 'member[type_of_phone_number]')
# 			select("#{@terms_of_membership_with_gateway.id}", :from => 'member[terms_of_membership_id]')
# 		}

# 		within("#table_contact_information") {	
# 			fill_in 'member[credit_card][number]', :with => "#{unsaved_member.active_credit_card.number}"
# 			fill_in 'member[credit_card][expire_month]', :with => "#{unsaved_member.active_credit_card.expire_month}"
# 			fill_in 'member[credit_card][expire_year]', :with => "#{unsaved_member.active_credit_card.expire_year}"
# 		}
    
#     alert_ok_js

#     assert_difference ['Member.count', 'CreditCard.count'] do
#     	click_link_or_button 'Create Member'
#     end

#     assert page.has_content?("#{unsaved_member.first_name} #{unsaved_member.last_name}")
#   end


# end