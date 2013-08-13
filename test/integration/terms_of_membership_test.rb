require 'test_helper'

class TermsOfMembershipTests < ActionController::IntegrationTest

	setup do
		init_test_setup
		@admin_agent = FactoryGirl.create(:confirmed_admin_agent)
		@partner = FactoryGirl.create(:partner)
		@club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id)
		sign_in_as(@admin_agent)
	end

	# test "Delete unused TOM" do
	# 	13.times { the_tom = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id) }
	# 	the_tom = TermsOfMembership.last
	# 	visit terms_of_memberships_path(@partner.prefix, @club.name)
	# 	within('#terms_of_memberships_table') do
	# 		find('.sorting_asc', :text => 'ID').click # Sorting desc to show the last tom we had created as the first row of the table
	# 		within("tr", :text => the_tom.id.to_s) do
	# 			confirm_ok_js
	# 			click_link_or_button "Destroy"
	# 		end
	# 	end
	# 	assert page.has_content?("was successfully destroyed.")
	# end

	# test "Do not delete a TOM with inactive memberships" do
	# 	27.times { the_tom = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id) }
	# 	the_tom = TermsOfMembership.last
	# 	the_lapsed_member = create_active_member(the_tom, :lapsed_member, nil, {}, { :created_by => @admin_agent })
	# 	visit terms_of_memberships_path(@partner.prefix, @club.name)
	# 	within('#terms_of_memberships_table') do
	# 		find('.sorting_asc', :text => 'ID').click # Sorting desc to show the last tom we had created as the first row of the table
	# 		within("tr", :text => the_tom.id.to_s) do
	# 			confirm_ok_js
	# 			click_link_or_button "Destroy"
	# 		end
	# 	end
	# 	assert page.has_content?("was not destroyed.")
	# end

	# test "Do not delete a TOM with active memberships" do
	# 	27.times { the_tom = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id) }
	# 	the_tom = TermsOfMembership.last
	# 	the_active_member = create_active_member(the_tom, :active_member, nil, {}, { :created_by => @admin_agent })
	# 	visit terms_of_memberships_path(@partner.prefix, @club.name)
	# 	within('#terms_of_memberships_table') do
	# 		find('.sorting_asc', :text => 'ID').click # Sorting desc to show the last tom we had created as the first row of the table
	# 		within("tr", :text => the_tom.id.to_s) do
	# 			confirm_ok_js
	# 			click_link_or_button "Destroy"
	# 		end
	# 	end
	# 	assert page.has_content?("was not destroyed.")
	# end

	# test "Create subcription plan with Initial Fee distinct of 0" do
	# 	tom_name = 'TOM Initial Fee greater than 0'
	# 	visit terms_of_memberships_path(@partner.prefix, @club.name)
	# 	click_link_or_button 'Add New Plan'
	# 	fill_in 'terms_of_membership_name', :with => tom_name
	# 	click_link_or_button 'Membership Terms'
	# 	fill_in 'initial_fee_amount', :with => '1'
	# 	fill_in 'trial_period_amount', :with => '0'
	# 	fill_in 'trial_period_lasting', :with => '0'
	# 	fill_in 'installment_amount', :with => '0'
	# 	fill_in 'installment_amount_days', :with => '0'
	# 	click_link_or_button 'Define Upgrades / Downgrades'
	# 	click_link_or_button 'Create Plan'
	# 	assert page.has_content?('was created Succesfully') # TOM was created
	# 	assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	# end

	# test "Create subcription plan with Initial Fee equal to 0" do
	# 	tom_name = 'TOM Initial Fee equal to 0'
	# 	visit terms_of_memberships_path(@partner.prefix, @club.name)
	# 	click_link_or_button 'Add New Plan'
	# 	fill_in 'terms_of_membership_name', :with => tom_name
	# 	click_link_or_button 'Membership Terms'
	# 	fill_in 'initial_fee_amount', :with => '0'
	# 	fill_in 'trial_period_amount', :with => '0'
	# 	fill_in 'trial_period_lasting', :with => '0'
	# 	fill_in 'installment_amount', :with => '0'
	# 	fill_in 'installment_amount_days', :with => '0'
	# 	click_link_or_button 'Define Upgrades / Downgrades'
	# 	click_link_or_button 'Create Plan'
	# 	assert page.has_content?('was created Succesfully') # TOM was created
	# 	assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	# end


	test "Create subcription plan with Free Trial Period in Days" do
		tom_name = 'TOM Trial Period in Days'
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		click_link_or_button 'Add New Plan'
		fill_in 'terms_of_membership_name', :with => tom_name
		click_link_or_button 'Membership Terms'
		fill_in 'initial_fee_amount', :with => '0'
		fill_in 'trial_period_amount', :with => '0'
		fill_in 'trial_period_lasting', :with => '5'
		select('Day(s)', :from => 'trial_period_lasting_time_span')
		fill_in 'installment_amount', :with => '0'
		fill_in 'installment_amount_days', :with => '0'
		click_link_or_button 'Define Upgrades / Downgrades'
		click_link_or_button 'Create Plan'
		assert page.has_content?('was created Succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end

	test "Create subcription plan with Free Trial Period in Months" do
		tom_name = 'TOM Trial Period in Months'
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		click_link_or_button 'Add New Plan'
		fill_in 'terms_of_membership_name', :with => tom_name
		click_link_or_button 'Membership Terms'
		fill_in 'initial_fee_amount', :with => '0'
		fill_in 'trial_period_amount', :with => '0'
		fill_in 'trial_period_lasting', :with => '5'
		select('Month(s)', :from => 'trial_period_lasting_time_span')
		fill_in 'installment_amount', :with => '0'
		fill_in 'installment_amount_days', :with => '0'
		click_link_or_button 'Define Upgrades / Downgrades'
		click_link_or_button 'Create Plan'
		assert page.has_content?('was created Succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end

	test "Create subcription plan with Paid Trial Period in Days" do
		tom_name = 'TOM with Paid Trial Period in Days'
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		click_link_or_button 'Add New Plan'
		fill_in 'terms_of_membership_name', :with => tom_name
		click_link_or_button 'Membership Terms'
		fill_in 'initial_fee_amount', :with => '0'
		fill_in 'trial_period_amount', :with => '100'
		fill_in 'trial_period_lasting', :with => '5'
		select('Day(s)', :from => 'trial_period_lasting_time_span')
		fill_in 'installment_amount', :with => '0'
		fill_in 'installment_amount_days', :with => '0'
		click_link_or_button 'Define Upgrades / Downgrades'
		click_link_or_button 'Create Plan'
		assert page.has_content?('was created Succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end

	test " Create subcription plan with Paid Trial Period in Months" do
		tom_name = 'TOM with Paid Trial Period in Months'
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		click_link_or_button 'Add New Plan'
		fill_in 'terms_of_membership_name', :with => tom_name
		click_link_or_button 'Membership Terms'
		fill_in 'initial_fee_amount', :with => '0'
		fill_in 'trial_period_amount', :with => '100'
		fill_in 'trial_period_lasting', :with => '5'
		select('Month(s)', :from => 'trial_period_lasting_time_span')
		fill_in 'installment_amount', :with => '0'
		fill_in 'installment_amount_days', :with => '0'
		click_link_or_button 'Define Upgrades / Downgrades'
		click_link_or_button 'Create Plan'
		assert page.has_content?('was created Succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end

end