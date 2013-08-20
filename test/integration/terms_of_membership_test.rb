require 'test_helper'

class TermsOfMembershipTests < ActionController::IntegrationTest

	setup do
		init_test_setup
		@admin_agent = FactoryGirl.create(:confirmed_admin_agent)
		@partner = FactoryGirl.create(:partner)
		@club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id)
		sign_in_as(@admin_agent)
	end


	# NEW

	test "Create subcription plan with Initial Fee distinct of 0" do
		tom_name = 'TOM Name'
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		click_link_or_button 'Add New Plan'
		fill_in 'terms_of_membership[name]', :with => tom_name
		click_link_or_button 'Define Membership Terms'
		sleep 3
		fill_in 'initial_fee_amount', :with => '1'
		fill_in 'trial_period_amount', :with => '0'
		fill_in 'trial_period_lasting', :with => '0'
		fill_in 'installment_amount', :with => '0'
		fill_in 'installment_amount_days', :with => '0'
		click_link_or_button 'Define Upgrades / Downgrades'
		sleep 3
	  choose('if_cannot_bill_member_cancel')
	  sleep 3
		click_link_or_button 'Create Plan'
		assert page.has_content?('was created succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end

	test "Create subcription plan with Initial Fee equal to 0" do
		tom_name = 'TOM Initial Fee equal to 0'
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		click_link_or_button 'Add New Plan'
		fill_in 'terms_of_membership[name]', :with => tom_name
		click_link_or_button 'Define Membership Terms'
		sleep 3
		fill_in 'initial_fee_amount', :with => '0'
		fill_in 'trial_period_amount', :with => '0'
		fill_in 'trial_period_lasting', :with => '0'
		fill_in 'installment_amount', :with => '0'
		fill_in 'installment_amount_days', :with => '0'
		click_link_or_button 'Define Upgrades / Downgrades'
		sleep 3
	  choose('if_cannot_bill_member_cancel')
	  sleep 3
		click_link_or_button 'Create Plan'
		assert page.has_content?('was created succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end

	test "Create subcription plan with Free Trial Period in Days" do
		tom_name = 'TOM Trial Period in Days'
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		click_link_or_button 'Add New Plan'
		fill_in 'terms_of_membership[name]', :with => tom_name
		click_link_or_button 'Define Membership Terms'
		sleep 3
		fill_in 'initial_fee_amount', :with => '0'
		fill_in 'trial_period_amount', :with => '0'
		fill_in 'trial_period_lasting', :with => '5'
		select('Day(s)', :from => 'trial_period_lasting_time_span')
		choose('is_payment_expected_yes')
		fill_in 'installment_amount', :with => '0'
		fill_in 'installment_amount_days', :with => '0'
		click_link_or_button 'Define Upgrades / Downgrades'
		sleep 3
		choose('if_cannot_bill_member_cancel')
		click_link_or_button 'Create Plan'
		assert page.has_content?('was created succesfully') # TOM was created
	end

	test "Create subcription plan with Free Trial Period in Months" do
		tom_name = 'TOM Trial Period in Months'
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		click_link_or_button 'Add New Plan'
		fill_in 'terms_of_membership[name]', :with => tom_name
		click_link_or_button 'Define Membership Terms'
		sleep 3
		fill_in 'initial_fee_amount', :with => '0'
		fill_in 'trial_period_amount', :with => '0'
		fill_in 'trial_period_lasting', :with => '5'
		select('Month(s)', :from => 'trial_period_lasting_time_span')
		fill_in 'installment_amount', :with => '0'
		fill_in 'installment_amount_days', :with => '0'
		click_link_or_button 'Define Upgrades / Downgrades'
		sleep 3
		choose('if_cannot_bill_member_cancel')
		click_link_or_button 'Create Plan'
		assert page.has_content?('was created succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end

	test "Create subcription plan with Paid Trial Period in Days" do
		tom_name = 'TOM with Paid Trial Period in Days'
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		click_link_or_button 'Add New Plan'
		fill_in 'terms_of_membership[name]', :with => tom_name
		click_link_or_button 'Define Membership Terms'
		sleep 3
		fill_in 'initial_fee_amount', :with => '0'
		fill_in 'trial_period_amount', :with => '100'
		fill_in 'trial_period_lasting', :with => '5'
		select('Day(s)', :from => 'trial_period_lasting_time_span')
		fill_in 'installment_amount', :with => '0'
		fill_in 'installment_amount_days', :with => '0'
		click_link_or_button 'Define Upgrades / Downgrades'
		sleep 3
		choose('if_cannot_bill_member_cancel')
		click_link_or_button 'Create Plan'
		assert page.has_content?('was created succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end

	test "Create subcription plan with Paid Trial Period in Months" do
		tom_name = 'TOM with Paid Trial Period in Months'
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		click_link_or_button 'Add New Plan'
		fill_in 'terms_of_membership[name]', :with => tom_name
		click_link_or_button 'Define Membership Terms'
		sleep 3
		fill_in 'initial_fee_amount', :with => '0'
		fill_in 'trial_period_amount', :with => '100'
		fill_in 'trial_period_lasting', :with => '5'
		select('Month(s)', :from => 'trial_period_lasting_time_span')
		fill_in 'installment_amount', :with => '0'
		fill_in 'installment_amount_days', :with => '0'
		click_link_or_button 'Define Upgrades / Downgrades'
		sleep 3
		choose('if_cannot_bill_member_cancel')
		click_link_or_button 'Create Plan'
		assert page.has_content?('was created succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end

	test "Create subcription plan with Recurring Amount in Months" do
		tom_name = 'TOM with Recurring Amount in Months'
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		click_link_or_button 'Add New Plan'
		fill_in 'terms_of_membership[name]', :with => tom_name
		click_link_or_button 'Define Membership Terms'
		sleep 3
		choose('is_payment_expected_yes')
		fill_in 'initial_fee_amount', :with => '0'
		fill_in 'trial_period_amount', :with => '0'
		fill_in 'trial_period_lasting', :with => '0'
		fill_in 'installment_amount', :with => '10'
		fill_in 'installment_amount_days', :with => '1'
		select('Month(s)', :from => 'installment_amount_days_time_span')
		click_link_or_button 'Define Upgrades / Downgrades'
		sleep 3
		choose('if_cannot_bill_member_cancel')
		click_link_or_button 'Create Plan'
		assert page.has_content?('was created succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end

	test "Create subcription plan with Recurring Amount in Years" do
		tom_name = 'TOM with Recurring Amount in Years'
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		click_link_or_button 'Add New Plan'
		fill_in 'terms_of_membership[name]', :with => tom_name
		click_link_or_button 'Define Membership Terms'
		sleep 3
		choose('is_payment_expected_yes')
		fill_in 'initial_fee_amount', :with => '0'
		fill_in 'trial_period_amount', :with => '0'
		fill_in 'trial_period_lasting', :with => '0'
		fill_in 'installment_amount', :with => '10'
		fill_in 'installment_amount_days', :with => '12'
		select('Month(s)', :from => 'installment_amount_days_time_span')
		click_link_or_button 'Define Upgrades / Downgrades'
		sleep 3
		choose('if_cannot_bill_member_cancel')
		click_link_or_button 'Create Plan'
		assert page.has_content?('was created succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end

	test "Create subcription plan with No payment is expected" do
		tom_name = 'TOM with No payment expected'
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		click_link_or_button 'Add New Plan'
		fill_in 'terms_of_membership[name]', :with => tom_name
		click_link_or_button 'Define Membership Terms'
		sleep 3
		fill_in 'initial_fee_amount', :with => '0'
		fill_in 'trial_period_amount', :with => '1'
		fill_in 'trial_period_lasting', :with => '0'
		choose('is_payment_expected_no')
		click_link_or_button 'Define Upgrades / Downgrades'
		sleep 3
		choose('if_cannot_bill_member_cancel')
		click_link_or_button 'Create Plan'
		assert page.has_content?('was created succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end

	test "Create subcription plan with Stop billing after at Subscription Terms - month" do
		tom_name = 'TOM with with Stop billing after Months'
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		click_link_or_button 'Add New Plan'
		fill_in 'terms_of_membership[name]', :with => tom_name
		click_link_or_button 'Define Membership Terms'
		sleep 3
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
		sleep 3
		choose('if_cannot_bill_member_cancel')
		click_link_or_button 'Create Plan'
		assert page.has_content?('was created succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end

	test "Create subcription plan with Stop billing after at Subscription Terms - days" do
		tom_name = 'TOM with with Stop billing after Days'
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		click_link_or_button 'Add New Plan'
		fill_in 'terms_of_membership[name]', :with => tom_name
		click_link_or_button 'Define Membership Terms'
		sleep 3
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
		sleep 3
		choose('if_cannot_bill_member_cancel')
		click_link_or_button 'Create Plan'
		assert page.has_content?('was created succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end

	test "Create a member at TOM created by Subscription Plan" do
		# First, create the TOM
		tom_name = 'TOM To Create the Member'
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		click_link_or_button 'Add New Plan'
		fill_in 'terms_of_membership[name]', :with => tom_name
		click_link_or_button 'Define Membership Terms'
		sleep 3
		fill_in 'initial_fee_amount', :with => '1'
		fill_in 'trial_period_amount', :with => '0'
		fill_in 'trial_period_lasting', :with => '0'
		fill_in 'installment_amount', :with => '0'
		fill_in 'installment_amount_days', :with => '0'
		click_link_or_button 'Define Upgrades / Downgrades'
		sleep 3
	  choose('if_cannot_bill_member_cancel')
		click_link_or_button 'Create Plan'
		assert page.has_content?('was created succesfully') # TOM was created
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
		fill_in 'terms_of_membership[name]', :with => tom_name
		click_link_or_button 'Define Membership Terms'
		sleep 3
		choose('is_payment_expected_yes')
		fill_in 'initial_fee_amount', :with => '0'
		fill_in 'trial_period_amount', :with => '0'
		fill_in 'trial_period_lasting', :with => '0'
		fill_in 'installment_amount', :with => '10'
		fill_in 'installment_amount_days', :with => '1'
		select('Month(s)', :from => 'installment_amount_days_time_span')
		click_link_or_button 'Define Upgrades / Downgrades'
		sleep 3
		choose('if_cannot_bill_member_suspend')
		fill_in 'if_cannot_bill_member_suspend_for', :with => '30'
		select('Day(s)', :from => 'if_cannot_bill_member_suspend_for_time_span')
		click_link_or_button 'Create Plan'
		assert page.has_content?('was created succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end

	test "Create subcription plan with Suspend for by months" do
		tom_name = 'TOM with Suspend Months'
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		click_link_or_button 'Add New Plan'
		fill_in 'terms_of_membership[name]', :with => tom_name
		click_link_or_button 'Define Membership Terms'
		choose('is_payment_expected_yes')
		sleep 3
		fill_in 'initial_fee_amount', :with => '0'
		fill_in 'trial_period_amount', :with => '0'
		fill_in 'trial_period_lasting', :with => '0'
		fill_in 'installment_amount', :with => '10'
		fill_in 'installment_amount_days', :with => '1'
		select('Month(s)', :from => 'installment_amount_days_time_span')
		click_link_or_button 'Define Upgrades / Downgrades'
		sleep 3
		choose('if_cannot_bill_member_suspend')
		fill_in 'if_cannot_bill_member_suspend_for', :with => '1'
		select('Month(s)', :from => 'if_cannot_bill_member_suspend_for_time_span')
		click_link_or_button 'Create Plan'
		assert page.has_content?('was created succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end

	test "Create subcription plan with Downgrade to option" do
		tom_to_downgrade = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
		tom_name = 'TOM with Downgrade To'
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		click_link_or_button 'Add New Plan'
		fill_in 'terms_of_membership[name]', :with => tom_name
		click_link_or_button 'Define Membership Terms'
		sleep 3
		choose('is_payment_expected_yes')
		fill_in 'initial_fee_amount', :with => '0'
		fill_in 'trial_period_amount', :with => '0'
		fill_in 'trial_period_lasting', :with => '0'
		fill_in 'installment_amount', :with => '10'
		fill_in 'installment_amount_days', :with => '1'
		select('Month(s)', :from => 'installment_amount_days_time_span')
		click_link_or_button 'Define Upgrades / Downgrades'
		sleep 3
		choose('if_cannot_bill_member_downgrade_to')
		select(tom_to_downgrade.name, :from => 'downgrade_to_tom')
		click_link_or_button 'Create Plan'
		assert page.has_content?('was created succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end


	# # EDIT

	test "Edit subcription plan with Initial Fee distinct of 0 - No membership associated" do
		tom_name = 'TOM Name'
		tom = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id, :name => tom_name)
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		within('#terms_of_memberships_table') do
			find('.sorting_asc', :text => 'ID').click # Sorting desc to show the last tom we had created as the first row of the table
			within("tr", :text => tom_name) do
				click_link_or_button "Edit"
			end
		end
		fill_in 'terms_of_membership[name]', :with => tom_name + ' Updated'
		click_link_or_button 'Edit Membership Terms'
		sleep 3
		choose('is_payment_expected_yes')
		fill_in 'initial_fee_amount', :with => '10'
		fill_in 'trial_period_amount', :with => '20'
		fill_in 'trial_period_lasting', :with => '30'
		fill_in 'installment_amount', :with => '10'
		fill_in 'installment_amount_days', :with => '1'
		choose('suscription_terms_until_cancelled')
		click_link_or_button 'Edit Upgrades / Downgrades'
		sleep 3
		choose('if_cannot_bill_member_cancel')
		click_link_or_button 'Update Plan'
		assert page.has_content?('was updated succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end

	test "Edit subcription plan with Initial Fee at 0 - No membership associated" do
		tom_name = 'TOM Name'
		tom = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id, :name => tom_name)
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		within('#terms_of_memberships_table') do
			find('.sorting_asc', :text => 'ID').click # Sorting desc to show the last tom we had created as the first row of the table
			within("tr", :text => tom_name) do
				click_link_or_button "Edit"
			end
		end
		fill_in 'terms_of_membership[name]', :with => tom_name + ' Updated'
		click_link_or_button 'Edit Membership Terms'
		sleep 3
		choose('is_payment_expected_yes')
		fill_in 'initial_fee_amount', :with => '0'
		fill_in 'trial_period_amount', :with => '20'
		fill_in 'trial_period_lasting', :with => '30'
		fill_in 'installment_amount', :with => '10'
		fill_in 'installment_amount_days', :with => '1'
		choose('suscription_terms_until_cancelled')
		click_link_or_button 'Edit Upgrades / Downgrades'
		sleep 3
		choose('if_cannot_bill_member_cancel')
		click_link_or_button 'Update Plan'
		assert page.has_content?('was updated succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end

	test "Update subcription plan with Free Trial Period by days - No membership associated" do
		tom_name = 'TOM Name'
		tom = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id, :name => tom_name)
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		within('#terms_of_memberships_table') do
			find('.sorting_asc', :text => 'ID').click # Sorting desc to show the last tom we had created as the first row of the table
			within("tr", :text => tom_name) do
				click_link_or_button "Edit"
			end
		end
		fill_in 'terms_of_membership[name]', :with => tom_name + ' Updated'
		click_link_or_button 'Edit Membership Terms'
		sleep 3
		choose('is_payment_expected_yes')
		fill_in 'initial_fee_amount', :with => '10'
		fill_in 'trial_period_amount', :with => '0'
		fill_in 'trial_period_lasting', :with => '10'
		select('Day(s)', :from => 'trial_period_lasting_time_span')
		fill_in 'installment_amount', :with => '10'
		fill_in 'installment_amount_days', :with => '1'
		choose('suscription_terms_until_cancelled')
		click_link_or_button 'Edit Upgrades / Downgrades'
		sleep 3
		choose('if_cannot_bill_member_cancel')
		click_link_or_button 'Update Plan'
		assert page.has_content?('was updated succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end

	test "Update subcription plan with Free Trial Period by months - No membership associated" do
		tom_name = 'TOM Name'
		tom = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id, :name => tom_name)
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		within('#terms_of_memberships_table') do
			find('.sorting_asc', :text => 'ID').click # Sorting desc to show the last tom we had created as the first row of the table
			within("tr", :text => tom_name) do
				click_link_or_button "Edit"
			end
		end
		fill_in 'terms_of_membership[name]', :with => tom_name + ' Updated'
		click_link_or_button 'Edit Membership Terms'
		sleep 3
		choose('is_payment_expected_yes')
		fill_in 'initial_fee_amount', :with => '10'
		fill_in 'trial_period_amount', :with => '0'
		fill_in 'trial_period_lasting', :with => '10'
		select('Month(s)', :from => 'trial_period_lasting_time_span')
		fill_in 'installment_amount', :with => '10'
		fill_in 'installment_amount_days', :with => '1'
		choose('suscription_terms_until_cancelled')
		click_link_or_button 'Edit Upgrades / Downgrades'
		sleep 3
		choose('if_cannot_bill_member_cancel')
		click_link_or_button 'Update Plan'
		assert page.has_content?('was updated succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end

	test "Update subcription plan with Paid Trial Period by days - No membership associated" do
		tom_name = 'TOM Name'
		tom = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id, :name => tom_name)
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		within('#terms_of_memberships_table') do
			find('.sorting_asc', :text => 'ID').click # Sorting desc to show the last tom we had created as the first row of the table
			within("tr", :text => tom_name) do
				click_link_or_button "Edit"
			end
		end
		fill_in 'terms_of_membership[name]', :with => tom_name + ' Updated'
		click_link_or_button 'Edit Membership Terms'
		sleep 3
		choose('is_payment_expected_yes')
		fill_in 'initial_fee_amount', :with => '10'
		fill_in 'trial_period_amount', :with => '20'
		fill_in 'trial_period_lasting', :with => '10'
		select('Day(s)', :from => 'trial_period_lasting_time_span')
		fill_in 'installment_amount', :with => '10'
		fill_in 'installment_amount_days', :with => '1'
		choose('suscription_terms_until_cancelled')
		click_link_or_button 'Edit Upgrades / Downgrades'
		sleep 3
		choose('if_cannot_bill_member_cancel')
		click_link_or_button 'Update Plan'
		assert page.has_content?('was updated succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end

	test "Update subcription plan with Paid Trial Period by month - No membership associated" do
		tom_name = 'TOM Name'
		tom = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id, :name => tom_name)
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		within('#terms_of_memberships_table') do
			find('.sorting_asc', :text => 'ID').click # Sorting desc to show the last tom we had created as the first row of the table
			within("tr", :text => tom_name) do
				click_link_or_button "Edit"
			end
		end
		fill_in 'terms_of_membership[name]', :with => tom_name + ' Updated'
		click_link_or_button 'Edit Membership Terms'
		sleep 3
		choose('is_payment_expected_yes')
		fill_in 'initial_fee_amount', :with => '10'
		fill_in 'trial_period_amount', :with => '20'
		fill_in 'trial_period_lasting', :with => '10'
		select('Month(s)', :from => 'trial_period_lasting_time_span')
		fill_in 'installment_amount', :with => '10'
		fill_in 'installment_amount_days', :with => '1'
		choose('suscription_terms_until_cancelled')
		click_link_or_button 'Edit Upgrades / Downgrades'
		sleep 3
		choose('if_cannot_bill_member_cancel')
		click_link_or_button 'Update Plan'
		assert page.has_content?('was updated succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end

	test "Update subcription plan with Recurring Amount by month - No membership associated" do
		tom_name = 'TOM Name'
		tom = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id, :name => tom_name)
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		within('#terms_of_memberships_table') do
			find('.sorting_asc', :text => 'ID').click # Sorting desc to show the last tom we had created as the first row of the table
			within("tr", :text => tom_name) do
				click_link_or_button "Edit"
			end
		end
		fill_in 'terms_of_membership[name]', :with => tom_name + ' Updated'
		click_link_or_button 'Edit Membership Terms'
		sleep 3
		choose('is_payment_expected_yes')
		fill_in 'initial_fee_amount', :with => '10'
		fill_in 'trial_period_amount', :with => '20'
		fill_in 'trial_period_lasting', :with => '10'
		select('Month(s)', :from => 'trial_period_lasting_time_span')
		fill_in 'installment_amount', :with => '10'
		fill_in 'installment_amount_days', :with => '6'
		select('Month(s)', :from => 'installment_amount_days_time_span')
		choose('suscription_terms_until_cancelled')
		click_link_or_button 'Edit Upgrades / Downgrades'
		sleep 3
		choose('if_cannot_bill_member_cancel')
		click_link_or_button 'Update Plan'
		assert page.has_content?('was updated succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end

	test "Update subcription plan with Recurring Amount by year - No membership associated" do
		tom_name = 'TOM Name'
		tom = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id, :name => tom_name)
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		within('#terms_of_memberships_table') do
			find('.sorting_asc', :text => 'ID').click # Sorting desc to show the last tom we had created as the first row of the table
			within("tr", :text => tom_name) do
				click_link_or_button "Edit"
			end
		end
		fill_in 'terms_of_membership[name]', :with => tom_name + ' Updated'
		click_link_or_button 'Edit Membership Terms'
		sleep 3
		choose('is_payment_expected_yes')
		fill_in 'initial_fee_amount', :with => '10'
		fill_in 'trial_period_amount', :with => '20'
		fill_in 'trial_period_lasting', :with => '10'
		select('Month(s)', :from => 'trial_period_lasting_time_span')
		fill_in 'installment_amount', :with => '10'
		fill_in 'installment_amount_days', :with => '24'
		select('Month(s)', :from => 'installment_amount_days_time_span')
		choose('suscription_terms_until_cancelled')
		click_link_or_button 'Edit Upgrades / Downgrades'
		sleep 3
		choose('if_cannot_bill_member_cancel')
		click_link_or_button 'Update Plan'
		assert page.has_content?('was updated succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end

	test "Update subcription plan with No payment is expected - No membership associated" do
		tom_name = 'TOM Name'
		tom = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id, :name => tom_name)
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		within('#terms_of_memberships_table') do
			find('.sorting_asc', :text => 'ID').click # Sorting desc to show the last tom we had created as the first row of the table
			within("tr", :text => tom_name) do
				click_link_or_button "Edit"
			end
		end
		fill_in 'terms_of_membership[name]', :with => tom_name + ' Updated'
		click_link_or_button 'Edit Membership Terms'
		sleep 3
		choose('is_payment_expected_no')
		fill_in 'initial_fee_amount', :with => '10'
		fill_in 'trial_period_amount', :with => '20'
		fill_in 'trial_period_lasting', :with => '30'
		choose('suscription_terms_until_cancelled')
		click_link_or_button 'Edit Upgrades / Downgrades'
		sleep 3
		choose('if_cannot_bill_member_cancel')
		click_link_or_button 'Update Plan'
		assert page.has_content?('was updated succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end

	test "Update subcription plan with Stop billing after at Subscription Terms - month  - No membership associated" do
		tom_name = 'TOM Name'
		tom = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id, :name => tom_name)
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		within('#terms_of_memberships_table') do
			find('.sorting_asc', :text => 'ID').click # Sorting desc to show the last tom we had created as the first row of the table
			within("tr", :text => tom_name) do
				click_link_or_button "Edit"
			end
		end
		fill_in 'terms_of_membership[name]', :with => tom_name + ' Updated'
		click_link_or_button 'Edit Membership Terms'
		sleep 3
		choose('is_payment_expected_yes')
		fill_in 'initial_fee_amount', :with => '10'
		fill_in 'trial_period_amount', :with => '20'
		fill_in 'trial_period_lasting', :with => '30'
		fill_in 'installment_amount', :with => '10'
		fill_in 'installment_amount_days', :with => '24'
		select('Month(s)', :from => 'installment_amount_days_time_span')
		choose('suscription_terms_stop_cancel_after')
		fill_in 'suscription_terms_stop_billing_after', :with => '10'
		select('Month(s)', :from => 'suscription_terms_stop_billing_after_time_span')
		click_link_or_button 'Edit Upgrades / Downgrades'
		sleep 3
		choose('if_cannot_bill_member_cancel')
		click_link_or_button 'Update Plan'
		assert page.has_content?('was updated succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end

	test "Update subcription plan with Stop billing after at Subscription Terms - day - No membership associated" do
		tom_name = 'TOM Name'
		tom = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id, :name => tom_name)
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		within('#terms_of_memberships_table') do
			find('.sorting_asc', :text => 'ID').click # Sorting desc to show the last tom we had created as the first row of the table
			within("tr", :text => tom_name) do
				click_link_or_button "Edit"
			end
		end
		fill_in 'terms_of_membership[name]', :with => tom_name + ' Updated'
		click_link_or_button 'Edit Membership Terms'
		sleep 3
		choose('is_payment_expected_yes')
		fill_in 'initial_fee_amount', :with => '10'
		fill_in 'trial_period_amount', :with => '20'
		fill_in 'trial_period_lasting', :with => '30'
		fill_in 'installment_amount', :with => '10'
		fill_in 'installment_amount_days', :with => '24'
		select('Month(s)', :from => 'installment_amount_days_time_span')
		choose('suscription_terms_stop_cancel_after')
		fill_in 'suscription_terms_stop_billing_after', :with => '10'
		select('Day(s)', :from => 'suscription_terms_stop_billing_after_time_span')
		click_link_or_button 'Edit Upgrades / Downgrades'
		sleep 3
		choose('if_cannot_bill_member_cancel')
		click_link_or_button 'Update Plan'
		assert page.has_content?('was updated succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end

	test "Create a member at TOM updated by Subscription Plan  - No membership associated" do
		# First, create the TOM and update it
		tom_name = 'TOM Name'
		tom = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id, :name => tom_name)
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		within('#terms_of_memberships_table') do
			find('.sorting_asc', :text => 'ID').click # Sorting desc to show the last tom we had created as the first row of the table
			within("tr", :text => tom_name) do
				click_link_or_button "Edit"
			end
		end
		fill_in 'terms_of_membership[name]', :with => tom_name + ' Updated'
		click_link_or_button 'Edit Membership Terms'
		sleep 3
		choose('is_payment_expected_yes')
		fill_in 'initial_fee_amount', :with => '10'
		fill_in 'trial_period_amount', :with => '20'
		fill_in 'trial_period_lasting', :with => '30'
		fill_in 'installment_amount', :with => '10'
		fill_in 'installment_amount_days', :with => '24'
		select('Month(s)', :from => 'installment_amount_days_time_span')
		choose('suscription_terms_stop_cancel_after')
		fill_in 'suscription_terms_stop_billing_after', :with => '10'
		select('Day(s)', :from => 'suscription_terms_stop_billing_after_time_span')
		click_link_or_button 'Edit Upgrades / Downgrades'
		sleep 3
		choose('if_cannot_bill_member_suspend')
		fill_in 'if_cannot_bill_member_suspend_for', :with => '10'
		select('Day(s)', :from => 'if_cannot_bill_member_suspend_for_time_span')
		click_link_or_button 'Update Plan'
		# Then, create the member
		the_tom = TermsOfMembership.last
		the_member = create_active_member(the_tom, :active_member, nil, {}, { :created_by => @admin_agent })
		visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => the_member.id)
		assert page.find('#table_membership_information').has_content?(tom_name) # TOM is in the table
	end

	test "Update subcription plan with Suspend for by days - No membership associated" do
		tom_name = 'TOM Name'
		tom = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id, :name => tom_name)
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		within('#terms_of_memberships_table') do
			find('.sorting_asc', :text => 'ID').click # Sorting desc to show the last tom we had created as the first row of the table
			within("tr", :text => tom_name) do
				click_link_or_button "Edit"
			end
		end
		fill_in 'terms_of_membership[name]', :with => tom_name + ' Updated'
		click_link_or_button 'Edit Membership Terms'
		sleep 3
		choose('is_payment_expected_yes')
		fill_in 'initial_fee_amount', :with => '10'
		fill_in 'trial_period_amount', :with => '20'
		fill_in 'trial_period_lasting', :with => '30'
		fill_in 'installment_amount', :with => '10'
		fill_in 'installment_amount_days', :with => '24'
		select('Month(s)', :from => 'installment_amount_days_time_span')
		choose('suscription_terms_stop_cancel_after')
		fill_in 'suscription_terms_stop_billing_after', :with => '10'
		select('Day(s)', :from => 'suscription_terms_stop_billing_after_time_span')
		click_link_or_button 'Edit Upgrades / Downgrades'
		sleep 3
		choose('if_cannot_bill_member_suspend')
		fill_in 'if_cannot_bill_member_suspend_for', :with => '10'
		select('Day(s)', :from => 'if_cannot_bill_member_suspend_for_time_span')
		click_link_or_button 'Update Plan'
		assert page.has_content?('was updated succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end

	test "Update subcription plan with Suspend for by month - No membership associated" do
		tom_name = 'TOM Name'
		tom = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id, :name => tom_name)
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		within('#terms_of_memberships_table') do
			find('.sorting_asc', :text => 'ID').click # Sorting desc to show the last tom we had created as the first row of the table
			within("tr", :text => tom_name) do
				click_link_or_button "Edit"
			end
		end
		fill_in 'terms_of_membership[name]', :with => tom_name + ' Updated'
		click_link_or_button 'Edit Membership Terms'
		sleep 3
		choose('is_payment_expected_yes')
		fill_in 'initial_fee_amount', :with => '10'
		fill_in 'trial_period_amount', :with => '20'
		fill_in 'trial_period_lasting', :with => '30'
		fill_in 'installment_amount', :with => '10'
		fill_in 'installment_amount_days', :with => '24'
		select('Month(s)', :from => 'installment_amount_days_time_span')
		choose('suscription_terms_stop_cancel_after')
		fill_in 'suscription_terms_stop_billing_after', :with => '1'
		select('Month(s)', :from => 'suscription_terms_stop_billing_after_time_span')
		click_link_or_button 'Edit Upgrades / Downgrades'
		sleep 3
		choose('if_cannot_bill_member_suspend')
		fill_in 'if_cannot_bill_member_suspend_for', :with => '10'
		select('Month(s)', :from => 'if_cannot_bill_member_suspend_for_time_span')
		click_link_or_button 'Update Plan'
		assert page.has_content?('was updated succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end

	test "Create subcription plan with Downgrade to option - No membership associated" do
		tom_name = 'TOM Name'
		tom = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id, :name => tom_name)
		tom_to_downgrade = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id, :name => 'Downgradable TOM')
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		within('#terms_of_memberships_table') do
			find('.sorting_asc', :text => 'ID').click # Sorting desc to show the last tom we had created as the first row of the table
			within("tr", :text => tom_name) do
				click_link_or_button "Edit"
			end
		end
		fill_in 'terms_of_membership[name]', :with => tom_name + ' Updated'
		click_link_or_button 'Edit Membership Terms'
		sleep 3
		choose('is_payment_expected_yes')
		fill_in 'initial_fee_amount', :with => '10'
		fill_in 'trial_period_amount', :with => '20'
		fill_in 'trial_period_lasting', :with => '30'
		fill_in 'installment_amount', :with => '10'
		fill_in 'installment_amount_days', :with => '24'
		select('Month(s)', :from => 'installment_amount_days_time_span')
		choose('suscription_terms_stop_cancel_after')
		fill_in 'suscription_terms_stop_billing_after', :with => '10'
		select('Day(s)', :from => 'suscription_terms_stop_billing_after_time_span')
		click_link_or_button 'Edit Upgrades / Downgrades'
		sleep 3
		choose('if_cannot_bill_member_downgrade_to')
		select(tom_to_downgrade.name, :from => 'downgrade_to_tom')
		click_link_or_button 'Update Plan'
		assert page.has_content?('was updated succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end

	test "Update subcription plan with external code and description - No membership associated" do
		tom_name = 'TOM Name'
		tom = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id, :name => tom_name)
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		within('#terms_of_memberships_table') do
			find('.sorting_asc', :text => 'ID').click # Sorting desc to show the last tom we had created as the first row of the table
			within("tr", :text => tom_name) do
				click_link_or_button "Edit"
			end
		end
		fill_in 'terms_of_membership[name]', :with => tom_name + ' Updated'
		fill_in 'terms_of_membership[api_role]', :with => 'API Role Updated'
		fill_in 'terms_of_membership[description]', :with => 'Description Updated'
		click_link_or_button 'Edit Membership Terms'
		sleep 3
		choose('is_payment_expected_yes')
		fill_in 'initial_fee_amount', :with => '10'
		fill_in 'trial_period_amount', :with => '20'
		fill_in 'trial_period_lasting', :with => '30'
		fill_in 'installment_amount', :with => '10'
		fill_in 'installment_amount_days', :with => '24'
		select('Month(s)', :from => 'installment_amount_days_time_span')
		choose('suscription_terms_until_cancelled')
		click_link_or_button 'Edit Upgrades / Downgrades'
		sleep 3
		choose('if_cannot_bill_member_cancel')
		click_link_or_button 'Update Plan'
		assert page.has_content?('was updated succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end

	test "Do not edit TOM with active (active, applied and provisional) membership" do
		27.times { the_tom = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id) }
		the_tom = TermsOfMembership.last
		the_member = create_active_member(the_tom, :active_member, nil, {}, { :created_by => @admin_agent })
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		within('#terms_of_memberships_table') do
			find('.sorting_asc', :text => 'ID').click # Sorting desc to show the last tom we had created as the first row of the table
			within("tr", :text => the_tom.id.to_s) do
				confirm_ok_js
				click_link_or_button "Edit"
			end
		end
		assert page.has_content?("can not be edited")
	end

	test "Do not edit TOM with inactive (lapsed) membership" do
		27.times { the_tom = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id) }
		the_tom = TermsOfMembership.last
		the_lapsed_member = create_active_member(the_tom, :lapsed_member, nil, {}, { :created_by => @admin_agent })
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		within('#terms_of_memberships_table') do
			find('.sorting_asc', :text => 'ID').click # Sorting desc to show the last tom we had created as the first row of the table
			within("tr", :text => the_tom.id.to_s) do
				confirm_ok_js
				click_link_or_button "Edit"
			end
		end
		assert page.has_content?("can not be edited")
	end


	# DELETE

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

end