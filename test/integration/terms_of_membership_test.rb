require 'test_helper'

class TermsOfMembershipTests < ActionController::IntegrationTest

	setup do
		init_test_setup
		@admin_agent = FactoryGirl.create(:confirmed_admin_agent)
		@partner = FactoryGirl.create(:partner)
		@club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id)
		sign_in_as(@admin_agent)
	end

	test "Delete unused TOM" do
		27.times { the_tom = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id) }
		the_tom = TermsOfMembership.last
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		within('#terms_of_memberships_table') do
			find('.sorting_asc', :text => 'ID').click # Sorting desc to show the last tom we had created as the first row of the table
			within("tr", :text => the_tom.id.to_s) do
				confirm_ok_js
				click_link_or_button "Destroy"
			end
		end
		assert page.has_content?("was successfully destroyed.")
	end

	test "Do not delete a TOM with inactive memberships" do
		27.times { the_tom = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id) }
		the_tom = TermsOfMembership.last
		the_lapsed_member = create_active_member(the_tom, :lapsed_member, nil, {}, { :created_by => @admin_agent })
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		within('#terms_of_memberships_table') do
			find('.sorting_asc', :text => 'ID').click # Sorting desc to show the last tom we had created as the first row of the table
			within("tr", :text => the_tom.id.to_s) do
				confirm_ok_js
				click_link_or_button "Destroy"
			end
		end
		assert page.has_content?("was not destroyed.")
	end

	test "Do not delete a TOM with active memberships" do
		27.times { the_tom = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id) }
		the_tom = TermsOfMembership.last
		the_active_member = create_active_member(the_tom, :active_member, nil, {}, { :created_by => @admin_agent })
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		within('#terms_of_memberships_table') do
			find('.sorting_asc', :text => 'ID').click # Sorting desc to show the last tom we had created as the first row of the table
			within("tr", :text => the_tom.id.to_s) do
				confirm_ok_js
				click_link_or_button "Destroy"
			end
		end
		assert page.has_content?("was not destroyed.")
	end

	test "Create subcription plan with Initial Fee distinct of 0" do
		tom_name = 'TOM Initial Fee greater than 0'
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		click_link_or_button 'Add New Plan'
		fill_in 'terms_of_membership_name', :with => tom_name
		click_link_or_button 'Define Membership Terms'
		fill_in 'initial_fee_amount', :with => '1'
		fill_in 'trial_period_amount', :with => '0'
		fill_in 'trial_period_lasting', :with => '0'
		fill_in 'installment_amount', :with => '0'
		fill_in 'installment_amount_days', :with => '0'
		click_link_or_button 'Define Upgrades / Downgrades'
	  choose('if_cannot_bill_member_cancel')
		click_link_or_button 'Create Plan'
		assert page.has_content?('was created Succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end

	test "Create subcription plan with Initial Fee equal to 0" do
		tom_name = 'TOM Initial Fee equal to 0'
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		click_link_or_button 'Add New Plan'
		fill_in 'terms_of_membership_name', :with => tom_name
		click_link_or_button 'Define Membership Terms'
		fill_in 'initial_fee_amount', :with => '0'
		fill_in 'trial_period_amount', :with => '0'
		fill_in 'trial_period_lasting', :with => '0'
		fill_in 'installment_amount', :with => '0'
		fill_in 'installment_amount_days', :with => '0'
		click_link_or_button 'Define Upgrades / Downgrades'
	  choose('if_cannot_bill_member_cancel')
		click_link_or_button 'Create Plan'
		assert page.has_content?('was created Succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end

	test "Create subcription plan with Free Trial Period in Days" do
		tom_name = 'TOM Trial Period in Days'
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		click_link_or_button 'Add New Plan'
		fill_in 'terms_of_membership_name', :with => tom_name
		click_link_or_button 'Define Membership Terms'
		fill_in 'initial_fee_amount', :with => '0'
		fill_in 'trial_period_amount', :with => '0'
		fill_in 'trial_period_lasting', :with => '5'
		select('Day(s)', :from => 'trial_period_lasting_time_span')
		choose('is_payment_expected_yes')
		fill_in 'installment_amount', :with => '0'
		fill_in 'installment_amount_days', :with => '0'
		click_link_or_button 'Define Upgrades / Downgrades'
		choose('if_cannot_bill_member_cancel')
		click_link_or_button 'Create Plan'
		assert page.has_content?('was created Succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end

	test "Create subcription plan with Free Trial Period in Months" do
		tom_name = 'TOM Trial Period in Months'
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		click_link_or_button 'Add New Plan'
		fill_in 'terms_of_membership_name', :with => tom_name
		click_link_or_button 'Define Membership Terms'
		fill_in 'initial_fee_amount', :with => '0'
		fill_in 'trial_period_amount', :with => '0'
		fill_in 'trial_period_lasting', :with => '5'
		select('Month(s)', :from => 'trial_period_lasting_time_span')
		fill_in 'installment_amount', :with => '0'
		fill_in 'installment_amount_days', :with => '0'
		click_link_or_button 'Define Upgrades / Downgrades'
		sleep 1
		choose('if_cannot_bill_member_cancel')
		click_link_or_button 'Create Plan'
		assert page.has_content?('was created Succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end

	test "Create subcription plan with Paid Trial Period in Days" do
		tom_name = 'TOM with Paid Trial Period in Days'
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		click_link_or_button 'Add New Plan'
		fill_in 'terms_of_membership_name', :with => tom_name
		click_link_or_button 'Define Membership Terms'
		fill_in 'initial_fee_amount', :with => '0'
		fill_in 'trial_period_amount', :with => '100'
		fill_in 'trial_period_lasting', :with => '5'
		select('Day(s)', :from => 'trial_period_lasting_time_span')
		fill_in 'installment_amount', :with => '0'
		fill_in 'installment_amount_days', :with => '0'
		click_link_or_button 'Define Upgrades / Downgrades'
		choose('if_cannot_bill_member_cancel')
		click_link_or_button 'Create Plan'
		assert page.has_content?('was created Succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end

	test "Create subcription plan with Paid Trial Period in Months" do
		tom_name = 'TOM with Paid Trial Period in Months'
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		click_link_or_button 'Add New Plan'
		fill_in 'terms_of_membership_name', :with => tom_name
		click_link_or_button 'Define Membership Terms'
		fill_in 'initial_fee_amount', :with => '0'
		fill_in 'trial_period_amount', :with => '100'
		fill_in 'trial_period_lasting', :with => '5'
		select('Month(s)', :from => 'trial_period_lasting_time_span')
		fill_in 'installment_amount', :with => '0'
		fill_in 'installment_amount_days', :with => '0'
		click_link_or_button 'Define Upgrades / Downgrades'
		choose('if_cannot_bill_member_cancel')
		click_link_or_button 'Create Plan'
		assert page.has_content?('was created Succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end

	test "Create subcription plan with Recurring Amount in Months" do
		tom_name = 'TOM with Recurring Amount in Months'
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		click_link_or_button 'Add New Plan'
		fill_in 'terms_of_membership_name', :with => tom_name
		click_link_or_button 'Define Membership Terms'
		choose('is_payment_expected_yes')
		fill_in 'initial_fee_amount', :with => '0'
		fill_in 'trial_period_amount', :with => '0'
		fill_in 'trial_period_lasting', :with => '0'
		fill_in 'installment_amount', :with => '10'
		fill_in 'installment_amount_days', :with => '1'
		select('Month(s)', :from => 'installment_amount_days_time_span')
		click_link_or_button 'Define Upgrades / Downgrades'
		choose('if_cannot_bill_member_cancel')
		click_link_or_button 'Create Plan'
		assert page.has_content?('was created Succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end

	test "Create subcription plan with Recurring Amount in Years" do
		tom_name = 'TOM with Recurring Amount in Years'
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		click_link_or_button 'Add New Plan'
		fill_in 'terms_of_membership_name', :with => tom_name
		click_link_or_button 'Define Membership Terms'
		choose('is_payment_expected_yes')
		fill_in 'initial_fee_amount', :with => '0'
		fill_in 'trial_period_amount', :with => '0'
		fill_in 'trial_period_lasting', :with => '0'
		fill_in 'installment_amount', :with => '10'
		fill_in 'installment_amount_days', :with => '12'
		select('Month(s)', :from => 'installment_amount_days_time_span')
		click_link_or_button 'Define Upgrades / Downgrades'
		choose('if_cannot_bill_member_cancel')
		click_link_or_button 'Create Plan'
		assert page.has_content?('was created Succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end

	test "Create subcription plan with No payment is expected" do
		tom_name = 'TOM with No payment expected'
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		click_link_or_button 'Add New Plan'
		fill_in 'terms_of_membership_name', :with => tom_name
		click_link_or_button 'Define Membership Terms'
		fill_in 'initial_fee_amount', :with => '0'
		fill_in 'trial_period_amount', :with => '1'
		fill_in 'trial_period_lasting', :with => '0'
		choose('is_payment_expected_no')
		click_link_or_button 'Define Upgrades / Downgrades'
		choose('if_cannot_bill_member_cancel')
		click_link_or_button 'Create Plan'
		assert page.has_content?('was created Succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end

	test "Create subcription plan with Stop billing after at Subscription Terms - month" do
		tom_name = 'TOM with with Stop billing after Months'
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		click_link_or_button 'Add New Plan'
		fill_in 'terms_of_membership_name', :with => tom_name
		click_link_or_button 'Define Membership Terms'
		choose('is_payment_expected_yes')
		fill_in 'initial_fee_amount', :with => '0'
		fill_in 'trial_period_amount', :with => '0'
		fill_in 'trial_period_lasting', :with => '0'
		fill_in 'installment_amount', :with => '1'
		fill_in 'installment_amount_days', :with => '1'
		choose('suscription_terms_stop_cancel_after')
		fill_in 'suscription_terms_stop_billing_after', :with => '1'
		select('Month(s)', :from => 'suscription_terms_stop_billing_after_time_span')
		click_link_or_button 'Define Upgrades / Downgrades'
		choose('if_cannot_bill_member_cancel')
		click_link_or_button 'Create Plan'
		assert page.has_content?('was created Succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end

	test "Create subcription plan with Stop billing after at Subscription Terms - days" do
		tom_name = 'TOM with with Stop billing after Days'
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		click_link_or_button 'Add New Plan'
		fill_in 'terms_of_membership_name', :with => tom_name
		click_link_or_button 'Define Membership Terms'
		choose('is_payment_expected_yes')
		fill_in 'initial_fee_amount', :with => '0'
		fill_in 'trial_period_amount', :with => '0'
		fill_in 'trial_period_lasting', :with => '0'
		fill_in 'installment_amount', :with => '1'
		fill_in 'installment_amount_days', :with => '1'
		choose('suscription_terms_stop_cancel_after')
		fill_in 'suscription_terms_stop_billing_after', :with => '1'
		select('Day(s)', :from => 'suscription_terms_stop_billing_after_time_span')
		click_link_or_button 'Define Upgrades / Downgrades'
		choose('if_cannot_bill_member_cancel')
		click_link_or_button 'Create Plan'
		assert page.has_content?('was created Succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end


	test "Create a member at TOM created by Subscription Plan" do
		# First, create the TOM
		tom_name = 'TOM To Create the Member'
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		click_link_or_button 'Add New Plan'
		fill_in 'terms_of_membership_name', :with => tom_name
		click_link_or_button 'Define Membership Terms'
		fill_in 'initial_fee_amount', :with => '1'
		fill_in 'trial_period_amount', :with => '0'
		fill_in 'trial_period_lasting', :with => '0'
		fill_in 'installment_amount', :with => '0'
		fill_in 'installment_amount_days', :with => '0'
		click_link_or_button 'Define Upgrades / Downgrades'
	  choose('if_cannot_bill_member_cancel')
		click_link_or_button 'Create Plan'
		assert page.has_content?('was created Succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
		# Then, create the member
		the_tom = TermsOfMembership.last
		the_member = create_active_member(the_tom, :active_member, nil, {}, { :created_by => @admin_agent })
		visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => the_member.id)
		assert page.find('#table_membership_information').has_content?(tom_name) # TOM is in the table
	end

	test "Create subcription plan with Suspend for by days" do
		tom_name = 'TOM with Suspend Days'
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		click_link_or_button 'Add New Plan'
		fill_in 'terms_of_membership_name', :with => tom_name
		click_link_or_button 'Define Membership Terms'
		choose('is_payment_expected_yes')
		fill_in 'initial_fee_amount', :with => '0'
		fill_in 'trial_period_amount', :with => '0'
		fill_in 'trial_period_lasting', :with => '0'
		fill_in 'installment_amount', :with => '10'
		fill_in 'installment_amount_days', :with => '1'
		select('Month(s)', :from => 'installment_amount_days_time_span')
		click_link_or_button 'Define Upgrades / Downgrades'
		choose('if_cannot_bill_member_suspend')
		fill_in 'if_cannot_bill_member_suspend_for', :with => '30'
		select('Day(s)', :from => 'if_cannot_bill_member_suspend_for_time_span')
		click_link_or_button 'Create Plan'
		assert page.has_content?('was created Succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end

	test "Create subcription plan with Suspend for by months" do
		tom_name = 'TOM with Suspend Months'
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		click_link_or_button 'Add New Plan'
		fill_in 'terms_of_membership_name', :with => tom_name
		click_link_or_button 'Define Membership Terms'
		choose('is_payment_expected_yes')
		fill_in 'initial_fee_amount', :with => '0'
		fill_in 'trial_period_amount', :with => '0'
		fill_in 'trial_period_lasting', :with => '0'
		fill_in 'installment_amount', :with => '10'
		fill_in 'installment_amount_days', :with => '1'
		select('Month(s)', :from => 'installment_amount_days_time_span')
		click_link_or_button 'Define Upgrades / Downgrades'
		choose('if_cannot_bill_member_suspend')
		fill_in 'if_cannot_bill_member_suspend_for', :with => '1'
		select('Month(s)', :from => 'if_cannot_bill_member_suspend_for_time_span')
		click_link_or_button 'Create Plan'
		assert page.has_content?('was created Succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end

	test "Create subcription plan with Downgrade to option" do
		tom_to_downgrade = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
		tom_name = 'TOM with Downgrade To'
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		click_link_or_button 'Add New Plan'
		fill_in 'terms_of_membership_name', :with => tom_name
		click_link_or_button 'Define Membership Terms'
		choose('is_payment_expected_yes')
		fill_in 'initial_fee_amount', :with => '0'
		fill_in 'trial_period_amount', :with => '0'
		fill_in 'trial_period_lasting', :with => '0'
		fill_in 'installment_amount', :with => '10'
		fill_in 'installment_amount_days', :with => '1'
		select('Month(s)', :from => 'installment_amount_days_time_span')
		click_link_or_button 'Define Upgrades / Downgrades'
		choose('if_cannot_bill_member_downgrade_to')
		select(tom_to_downgrade.name, :from => 'downgrade_to_tom')
		click_link_or_button 'Create Plan'
		assert page.has_content?('was created Succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end






























end