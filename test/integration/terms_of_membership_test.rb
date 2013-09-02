require 'test_helper'

class TermsOfMembershipTests < ActionController::IntegrationTest

	setup do
		@admin_agent = FactoryGirl.create(:confirmed_admin_agent)
		@partner = FactoryGirl.create(:partner)
		@club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id)
		sign_in_as(@admin_agent)
	end

	def fill_in_form(options = {}, options_for_select = {}, options_for_check = [])		
		options_for_check.each do |value|
			choose(value)
		end

		options_for_select.each do |field, value|
			select(value, :from => field)
		end

		options.each do |field, value|
			fill_in field, :with => value
		end
	end

	def fill_in_step_1(name = nil, external_code = nil, description = nil)
		find("label", :text => "Subscription Plan Name")
		fill_in 'terms_of_membership[name]', :with => name if name
		fill_in 'terms_of_membership[api_role]', :with => external_code if external_code
		fill_in 'terms_of_membership[description]', :with => description if description
	end

	def fill_in_step_2(options = {}, options_for_select = [], options_for_check = {})
		find("label", :text => "Initial Fee Amount")
		fill_in_form(options, options_for_select, options_for_check)
	end


	# # # NEW

	test "Create subcription plan with Initial Fee distinct of 0" do
		tom_name = 'TOM Name'
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		click_link_or_button 'Add New Plan'

		fill_in_step_1(tom_name)
		click_link_or_button 'Define Membership Terms'
		fill_in_step_2({initial_fee_amount:1, trial_period_amount:0, trial_period_lasting:0, installment_amount:0, installment_amount_days:0})
		click_link_or_button 'Define Upgrades / Downgrades'
		
		find("label", :text => "If we cannot bill a member then")
	  choose('if_cannot_bill_member_cancel')
		click_link_or_button 'Create Plan'
		assert page.has_content?('was created succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end

	test "Create subcription plan with Initial Fee equal to 0" do
		tom_name = 'TOM Initial Fee equal to 0'
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		click_link_or_button 'Add New Plan'

		fill_in_step_1(tom_name)
		click_link_or_button 'Define Membership Terms'
		fill_in_step_2({initial_fee_amount:0, trial_period_amount:0, trial_period_lasting:0, installment_amount:0, installment_amount_days:0})
		click_link_or_button 'Define Upgrades / Downgrades'
		
		find("label", :text => "If we cannot bill a member then")
	  choose('if_cannot_bill_member_cancel')
		click_link_or_button 'Create Plan'
		assert page.has_content?('was created succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end

	test "Create subcription plan with Free Trial Period in Days" do
		tom_name = 'TOM Trial Period in Days'
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		click_link_or_button 'Add New Plan'

		fill_in_step_1(tom_name)
		click_link_or_button 'Define Membership Terms'
		fill_in_step_2({initial_fee_amount:0, trial_period_amount:0, trial_period_lasting:0, installment_amount:0, installment_amount_days:0})
		click_link_or_button 'Define Upgrades / Downgrades'

		find("label", :text => "If we cannot bill a member then")
		choose('if_cannot_bill_member_cancel')
		click_link_or_button 'Create Plan'
		assert page.has_content?('was created succesfully') # TOM was created
	end

	test "Create subcription plan with Free Trial Period in Months" do
		tom_name = 'TOM Trial Period in Months'
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		click_link_or_button 'Add New Plan'

		fill_in_step_1(tom_name)
		click_link_or_button 'Define Membership Terms'
		fill_in_step_2({initial_fee_amount:0, trial_period_amount:0, trial_period_lasting:0, installment_amount:0, installment_amount_days:0},{trial_period_lasting_time_span:"Month(s)"})
		click_link_or_button 'Define Upgrades / Downgrades'
		
		find("label", :text => "If we cannot bill a member then")
		choose('if_cannot_bill_member_cancel')
		click_link_or_button 'Create Plan'
		assert page.has_content?('was created succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end

	test "Create subcription plan with Paid Trial Period in Days" do
		tom_name = 'TOM with Paid Trial Period in Days'
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		click_link_or_button 'Add New Plan'
		
		fill_in_step_1(tom_name)
		click_link_or_button 'Define Membership Terms'
		fill_in_step_2({initial_fee_amount:0, trial_period_amount:100, trial_period_lasting:5, installment_amount:0, installment_amount_days:0},{trial_period_lasting_time_span:"Day(s)"})
		click_link_or_button 'Define Upgrades / Downgrades'

		find("label", :text => "If we cannot bill a member then")
		choose('if_cannot_bill_member_cancel')
		click_link_or_button 'Create Plan'
		assert page.has_content?('was created succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end

	test "Create subcription plan with Paid Trial Period in Months" do
		tom_name = 'TOM with Paid Trial Period in Months'
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		click_link_or_button 'Add New Plan'
		
		fill_in_step_1(tom_name)
		click_link_or_button 'Define Membership Terms'
		fill_in_step_2({initial_fee_amount:0, trial_period_amount:100, trial_period_lasting:5, installment_amount:0, installment_amount_days:0},{trial_period_lasting_time_span:"Month(s)"})
		click_link_or_button 'Define Upgrades / Downgrades'

		find("label", :text => "If we cannot bill a member then")
		choose('if_cannot_bill_member_cancel')
		click_link_or_button 'Create Plan'
		assert page.has_content?('was created succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end

	test "Create subcription plan with Recurring Amount in Months" do
		tom_name = 'TOM with Recurring Amount in Months'
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		click_link_or_button 'Add New Plan'

		fill_in_step_1(tom_name)
		click_link_or_button 'Define Membership Terms'
		fill_in_step_2({initial_fee_amount:0, trial_period_amount:0, trial_period_lasting:0, installment_amount:10, installment_amount_days:0},{installment_amount_days_time_span:"Month(s)"})
		click_link_or_button 'Define Upgrades / Downgrades'

		find("label", :text => "If we cannot bill a member then")
		choose('if_cannot_bill_member_cancel')
		click_link_or_button 'Create Plan'
		assert page.has_content?('was created succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end

	test "Create subcription plan with Recurring Amount in Years" do
		tom_name = 'TOM with Recurring Amount in Years'
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		click_link_or_button 'Add New Plan'

		fill_in_step_1(tom_name)
		click_link_or_button 'Define Membership Terms'
		fill_in_step_2({initial_fee_amount:0, trial_period_amount:0, trial_period_lasting:0, installment_amount:10, installment_amount_days:12},{installment_amount_days_time_span:"Month(s)"})
		click_link_or_button 'Define Upgrades / Downgrades'

		find("label", :text => "If we cannot bill a member then")
		choose('if_cannot_bill_member_cancel')
		click_link_or_button 'Create Plan'
		assert page.has_content?('was created succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end

	test "Create subcription plan with No payment is expected" do
		tom_name = 'TOM with No payment expected'
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		click_link_or_button 'Add New Plan'

		fill_in_step_1(tom_name)
		click_link_or_button 'Define Membership Terms'
		fill_in_step_2({initial_fee_amount:0, trial_period_amount:1, trial_period_lasting:0},{},["is_payment_expected_no"])
		click_link_or_button 'Define Upgrades / Downgrades'

		find("label", :text => "If we cannot bill a member then")
		choose('if_cannot_bill_member_cancel')
		click_link_or_button 'Create Plan'
		assert page.has_content?('was created succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end

	test "Create subcription plan with Stop billing after at Subscription Terms - month" do
		tom_name = 'TOM with with Stop billing after Months'
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		click_link_or_button 'Add New Plan'

		fill_in_step_1(tom_name)
		click_link_or_button 'Define Membership Terms'
		fill_in_step_2({initial_fee_amount:0, trial_period_amount:1, trial_period_lasting:0, installment_amount:1, installment_amount_days:1,subscription_terms_stop_billing_after:0},{subscription_terms_stop_billing_after_time_span:"Month(s)"},["subscription_terms_stop_cancel_after"])
		click_link_or_button 'Define Upgrades / Downgrades'

		find("label", :text => "If we cannot bill a member then")
		choose('if_cannot_bill_member_cancel')
		click_link_or_button 'Create Plan'
		assert page.has_content?('was created succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end

	test "Create subcription plan with Stop billing after at Subscription Terms - days" do
		tom_name = 'TOM with with Stop billing after Days'
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		click_link_or_button 'Add New Plan'

		fill_in_step_1(tom_name)
		click_link_or_button 'Define Membership Terms'
		fill_in_step_2({initial_fee_amount:0, trial_period_amount:1, trial_period_lasting:0, installment_amount:1, installment_amount_days:1,subscription_terms_stop_billing_after:0},{subscription_terms_stop_billing_after_time_span:"Day(s)"},["subscription_terms_stop_cancel_after"])
		click_link_or_button 'Define Upgrades / Downgrades'

		find("label", :text => "If we cannot bill a member then")
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
		
		fill_in_step_1(tom_name)
		click_link_or_button 'Define Membership Terms'
		fill_in_step_2({initial_fee_amount:1, trial_period_amount:0, trial_period_lasting:0, installment_amount:0, installment_amount_days:0})
		click_link_or_button 'Define Upgrades / Downgrades'
		
		find("label", :text => "If we cannot bill a member then")
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
		
		fill_in_step_1(tom_name)
		click_link_or_button 'Define Membership Terms'
		fill_in_step_2({initial_fee_amount:1, trial_period_amount:0, trial_period_lasting:0, installment_amount:10, installment_amount_days:1},{installment_amount_days_time_span:"Month(s)"})
		click_link_or_button 'Define Upgrades / Downgrades'
		
		find("label", :text => "If we cannot bill a member then")
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

		fill_in_step_1(tom_name)
		click_link_or_button 'Define Membership Terms'
		fill_in_step_2({initial_fee_amount:1, trial_period_amount:0, trial_period_lasting:0, installment_amount:10, installment_amount_days:1},{installment_amount_days_time_span:"Month(s)"})
		click_link_or_button 'Define Upgrades / Downgrades'
		
		find("label", :text => "If we cannot bill a member then")
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

		fill_in_step_1(tom_name)
		click_link_or_button 'Define Membership Terms'
		fill_in_step_2({initial_fee_amount:1, trial_period_amount:0, trial_period_lasting:0, installment_amount:10, installment_amount_days:1},{installment_amount_days_time_span:"Month(s)"})
		click_link_or_button 'Define Upgrades / Downgrades'
		
		find("label", :text => "If we cannot bill a member then")
		choose('if_cannot_bill_member_downgrade_to')
		select(tom_to_downgrade.name, :from => 'downgrade_to_tom')
		click_link_or_button 'Create Plan'
		assert page.has_content?('was created succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end

	test "Create a new TOM with club cash and enroll a member with it" do
		tom_name = 'TOM Name with club cash'
		amount_of_club_cash = 80
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		click_link_or_button 'Add New Plan'

		fill_in_step_1(tom_name)
		click_link_or_button 'Define Membership Terms'
		fill_in_step_2({initial_fee_amount:1, trial_period_amount:0, trial_period_lasting:0, installment_amount:0, installment_amount_days:0, club_cash_amount:amount_of_club_cash})
		click_link_or_button 'Define Upgrades / Downgrades'

		find_button("Create Plan")
	  choose('if_cannot_bill_member_cancel')
		click_link_or_button 'Create Plan'
		assert page.has_content?('was created succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table

		@terms_of_membership = TermsOfMembership.find_by_name tom_name
    unsaved_member =  FactoryGirl.build(:active_member, :club_id => @terms_of_membership.club_id)
    credit_card = FactoryGirl.build(:credit_card_master_card)
    enrollment_info = FactoryGirl.build(:enrollment_info)
    create_member_by_sloop(@admin_agent, unsaved_member, credit_card, enrollment_info, @terms_of_membership)
    @saved_member = Member.find_by_email(unsaved_member.email)  
    visit show_member_path(:partner_prefix => @terms_of_membership.club.partner.prefix, :club_prefix => @terms_of_membership.club.name, :member_prefix => @saved_member.id)
    within("#td_mi_club_cash_amount") { assert page.has_content?(amount_of_club_cash) }
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

		fill_in_step_1(tom_name + ' Updated')
		click_link_or_button 'Edit Membership Terms'
		fill_in_step_2({initial_fee_amount:10, trial_period_amount:20, trial_period_lasting:30, installment_amount:10, installment_amount_days:1},{},["is_payment_expected_yes","subscription_terms_until_cancelled"])
		click_link_or_button 'Edit Upgrades / Downgrades'
		
		find("label", :text => "If we cannot bill a member then")
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

		fill_in_step_1(tom_name + ' Updated')
		click_link_or_button 'Edit Membership Terms'
		fill_in_step_2({initial_fee_amount:0, trial_period_amount:20, trial_period_lasting:30, installment_amount:10, installment_amount_days:1},{},["is_payment_expected_yes","subscription_terms_until_cancelled"])
		click_link_or_button 'Edit Upgrades / Downgrades'

		find("label", :text => "If we cannot bill a member then")
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
		
		fill_in_step_1(tom_name + ' Updated')
		click_link_or_button 'Edit Membership Terms'
		fill_in_step_2({initial_fee_amount:10, trial_period_amount:0, trial_period_lasting:10, installment_amount:10, installment_amount_days:1},{trial_period_lasting_time_span:"Day(s)"},["is_payment_expected_yes","subscription_terms_until_cancelled"])
		click_link_or_button 'Edit Upgrades / Downgrades'
		
		find("label", :text => "If we cannot bill a member then")
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
		
		fill_in_step_1(tom_name + ' Updated')
		click_link_or_button 'Edit Membership Terms'
		fill_in_step_2({initial_fee_amount:10, trial_period_amount:0, trial_period_lasting:10, installment_amount:10, installment_amount_days:1},{trial_period_lasting_time_span:"Month(s)"},["is_payment_expected_yes","subscription_terms_until_cancelled"])
		click_link_or_button 'Edit Upgrades / Downgrades'
		
		find("label", :text => "If we cannot bill a member then")
		choose('if_cannot_bill_member_cancel')
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

		fill_in_step_1(tom_name + ' Updated')
		click_link_or_button 'Edit Membership Terms'
		fill_in_step_2({initial_fee_amount:10, trial_period_amount:20, trial_period_lasting:10, installment_amount:10, installment_amount_days:1},{trial_period_lasting_time_span:"Day(s)"},["is_payment_expected_yes","subscription_terms_until_cancelled"])
		click_link_or_button 'Edit Upgrades / Downgrades'
		
		find("label", :text => "If we cannot bill a member then")
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

		fill_in_step_1(tom_name + ' Updated')
		click_link_or_button 'Edit Membership Terms'
		fill_in_step_2({initial_fee_amount:10, trial_period_amount:20, trial_period_lasting:10, installment_amount:10, installment_amount_days:1},{trial_period_lasting_time_span:"Month(s)"},["is_payment_expected_yes","subscription_terms_until_cancelled"])
		click_link_or_button 'Edit Upgrades / Downgrades'
		
		find("label", :text => "If we cannot bill a member then")
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

		fill_in_step_1(tom_name + ' Updated')
		click_link_or_button 'Edit Membership Terms'
		fill_in_step_2({initial_fee_amount:10, trial_period_amount:20, trial_period_lasting:10, installment_amount:10, installment_amount_days:6},{trial_period_lasting_time_span:"Month(s)",installment_amount_days_time_span:"Month(s)"},["is_payment_expected_yes","subscription_terms_until_cancelled"])
		click_link_or_button 'Edit Upgrades / Downgrades'
		
		find("label", :text => "If we cannot bill a member then")
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

		fill_in_step_1(tom_name + ' Updated')
		click_link_or_button 'Edit Membership Terms'
		fill_in_step_2({initial_fee_amount:10, trial_period_amount:20, trial_period_lasting:10, installment_amount:10, installment_amount_days:24},{trial_period_lasting_time_span:"Month(s)",installment_amount_days_time_span:"Month(s)"},["is_payment_expected_yes","subscription_terms_until_cancelled"])
		click_link_or_button 'Edit Upgrades / Downgrades'
		
		find("label", :text => "If we cannot bill a member then")
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

		fill_in_step_1(tom_name + ' Updated')
		click_link_or_button 'Edit Membership Terms'
		fill_in_step_2({initial_fee_amount:10, trial_period_amount:20, trial_period_lasting:30},{trial_period_lasting_time_span:"Month(s)"},["is_payment_expected_no","subscription_terms_until_cancelled"])
		click_link_or_button 'Edit Upgrades / Downgrades'
		
		find("label", :text => "If we cannot bill a member then")
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

		fill_in_step_1(tom_name + ' Updated')
		click_link_or_button 'Edit Membership Terms'
		fill_in_step_2({initial_fee_amount:10, trial_period_amount:20, trial_period_lasting:30, installment_amount:10, installment_amount_days:24},{subscription_terms_stop_billing_after_time_span:"Month(s)",installment_amount_days_time_span:"Month(s)"},["is_payment_expected_yes","subscription_terms_stop_cancel_after"])
		click_link_or_button 'Edit Upgrades / Downgrades'
		
		find("label", :text => "If we cannot bill a member then")
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

		fill_in_step_1(tom_name + ' Updated')
		click_link_or_button 'Edit Membership Terms'
		fill_in_step_2({initial_fee_amount:10, trial_period_amount:20, trial_period_lasting:30, installment_amount:10, installment_amount_days:24, subscription_terms_stop_billing_after:10},{installment_amount_days_time_span:"Month(s)",subscription_terms_stop_billing_after_time_span:"Day(s)"},["is_payment_expected_yes","subscription_terms_stop_cancel_after"])
		click_link_or_button 'Edit Upgrades / Downgrades'
		
		find("label", :text => "If we cannot bill a member then")
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

		fill_in_step_1(tom_name + ' Updated')
		click_link_or_button 'Edit Membership Terms'
		fill_in_step_2({initial_fee_amount:10, trial_period_amount:20, trial_period_lasting:30, 
			              installment_amount:10, installment_amount_days:24, subscription_terms_stop_billing_after:10},
								   {installment_amount_days_time_span: 'Month(s)', subscription_terms_stop_billing_after_time_span: "Day(s)"},
		               ["is_payment_expected_yes", "subscription_terms_stop_cancel_after"])
		click_link_or_button 'Edit Upgrades / Downgrades'
		
		find("label", :text => "If we cannot bill a member then")
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

		fill_in_step_1(tom_name + ' Updated')
		click_link_or_button 'Edit Membership Terms'
		fill_in_step_2({initial_fee_amount:10, trial_period_amount:20, trial_period_lasting:30, 
			              installment_amount:10, installment_amount_days:24, subscription_terms_stop_billing_after:10},
								   {installment_amount_days_time_span: 'Month(s)', subscription_terms_stop_billing_after_time_span: "Day(s)"},
		               ["is_payment_expected_yes", "subscription_terms_stop_cancel_after"])
		click_link_or_button 'Edit Upgrades / Downgrades'
		
		find("label", :text => "If we cannot bill a member then")
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

		fill_in_step_1(tom_name + ' Updated')
		click_link_or_button 'Edit Membership Terms'
		fill_in_step_2({initial_fee_amount:10, trial_period_amount:20, trial_period_lasting:30, 
			              installment_amount:10, installment_amount_days:24, subscription_terms_stop_billing_after:1},
								   {installment_amount_days_time_span: 'Month(s)', subscription_terms_stop_billing_after_time_span: "Month(s)"},
		               ["is_payment_expected_yes", "subscription_terms_stop_cancel_after"])
		click_link_or_button 'Edit Upgrades / Downgrades'
		
		find("label", :text => "If we cannot bill a member then")
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

		fill_in_step_1(tom_name + ' Updated')
		click_link_or_button 'Edit Membership Terms'
		fill_in_step_2({initial_fee_amount:10, trial_period_amount:20, trial_period_lasting:30, 
			              installment_amount:10, installment_amount_days:24, subscription_terms_stop_billing_after:10},
								   {installment_amount_days_time_span: 'Month(s)', subscription_terms_stop_billing_after_time_span: "Day(s)"},
		               ["is_payment_expected_yes", "subscription_terms_stop_cancel_after"])
		click_link_or_button 'Edit Upgrades / Downgrades'
		
		find("label", :text => "If we cannot bill a member then")
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

		fill_in_step_1(tom_name + ' Updated','API Role Updated','Description Updated')
		click_link_or_button 'Edit Membership Terms'
		fill_in_step_2({initial_fee_amount:10, trial_period_amount:20, trial_period_lasting:30, 
			              installment_amount:10, installment_amount_days:24},
								   {installment_amount_days_time_span: 'Month(s)', subscription_terms_stop_billing_after_time_span: "Day(s)"},
		               ["is_payment_expected_yes", "subscription_terms_until_cancelled"])
		click_link_or_button 'Edit Upgrades / Downgrades'
		
		find("label", :text => "If we cannot bill a member then")
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

	test "Edit TOM without members and add club cash" do
		tom_name = 'TOM Name'
		tom = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id, :name => tom_name)
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		within('#terms_of_memberships_table') do
			find('.sorting_asc', :text => 'ID').click # Sorting desc to show the last tom we had created as the first row of the table
			within("tr", :text => tom_name) do
				click_link_or_button "Edit"
			end
		end

		fill_in_step_1
		click_link_or_button 'Edit Membership Terms'
		fill_in_step_2({initial_fee_amount:1, trial_period_amount:0, trial_period_lasting:0, installment_amount:0, installment_amount_days:0, club_cash_amount:100})
		click_link_or_button 'Edit Upgrades / Downgrades'

		find_button("Update Plan")
	  choose('if_cannot_bill_member_cancel')
		click_link_or_button 'Update Plan'
		assert page.has_content?('was updated succesfully') # TOM was updated
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end

	test "Delete club cash at TOM - TOM without members" do
		tom_name = 'TOM Name'
		tom = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id, :name => tom_name)
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		within('#terms_of_memberships_table') do
			find('.sorting_asc', :text => 'ID').click # Sorting desc to show the last tom we had created as the first row of the table
			within("tr", :text => tom_name) do
				click_link_or_button "Edit"
			end
		end

		fill_in_step_1
		click_link_or_button 'Edit Membership Terms'
		fill_in_step_2({initial_fee_amount:1, trial_period_amount:0, trial_period_lasting:0, installment_amount:0, installment_amount_days:0, club_cash_amount:0})
		click_link_or_button 'Edit Upgrades / Downgrades'

		find_button("Update Plan")
	  choose('if_cannot_bill_member_cancel')
		click_link_or_button 'Update Plan'
		assert page.has_content?('was updated succesfully') # TOM was updated
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
		tom.reload
		assert_equal tom.club_cash_amount.to_i, 0
	end

	test "Edit TOM without members and add club cash " do
		tom_name = 'TOM Name'
		club_cash_amount = 50
		tom = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id, :name => tom_name)
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		within('#terms_of_memberships_table') do
			find('.sorting_asc', :text => 'ID').click # Sorting desc to show the last tom we had created as the first row of the table
			within("tr", :text => tom_name) do
				click_link_or_button "Edit"
			end
		end

		fill_in_step_1
		click_link_or_button 'Edit Membership Terms'
		fill_in_step_2({initial_fee_amount:1, trial_period_amount:0, trial_period_lasting:0, installment_amount:0, installment_amount_days:0, club_cash_amount:club_cash_amount})
		click_link_or_button 'Edit Upgrades / Downgrades'

		find_button("Update Plan")
	  choose('if_cannot_bill_member_cancel')
		click_link_or_button 'Update Plan'
		assert page.has_content?('was updated succesfully') # TOM was updated
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
		tom.reload
		assert_equal tom.club_cash_amount.to_i, club_cash_amount.to_i
	end

	# # # DELETE

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