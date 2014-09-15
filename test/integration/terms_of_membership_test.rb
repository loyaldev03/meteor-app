require 'test_helper'

class TermsOfMembershipTests < ActionController::IntegrationTest
	setup do
		@admin_agent = FactoryGirl.create(:confirmed_admin_agent)
		@partner = FactoryGirl.create(:partner)
		@club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id)
	end

	def fill_in_form(options = {}, options_for_select = {}, options_for_check = [])
		options_for_check.each do |value|
			choose(value)
		end

		options_for_select.each do |field, value|
			select(value, :from => field)
		end

		options.each do |field, value|
			fill_in field, :with => value unless [:initial_fee_amount, :trial_period_amount].include? field
		end
	end

	def fill_in_step_1(name = nil, external_code = nil, description = nil)
		find(".step_selected", :text => "1")
		fill_in 'terms_of_membership[name]', :with => name if name
		fill_in 'terms_of_membership[api_role]', :with => external_code if external_code
		fill_in 'terms_of_membership[description]', :with => description if description
	end

	def fill_in_step_2(options = {}, options_for_select = [], options_for_check = {})
		find(".step_selected", :text => "2")
		fill_in_form(options, options_for_select, options_for_check)
	end


	# NEW

	test "Create subcription plan with Initial Fee distinct of 0" do
		sign_in_as(@admin_agent)
		tom_name = 'TOM Name'
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		click_link_or_button 'Add New Plan'

		fill_in_step_1(tom_name)
		click_link_or_button 'Define Membership Terms'
		fill_in_step_2({initial_fee_amount:1, trial_period_amount:0, trial_period_lasting:0, installment_amount:0, installment_amount_days:1})
		click_link_or_button 'Define Upgrades / Downgrades'
		
		find("label", :text => "If we cannot bill an user then")
	  choose('if_cannot_bill_user_cancel')
		click_link_or_button 'Create Plan'
		assert page.has_content?('was created succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end

	test "Create subcription plan with Initial Fee equal to 0" do
		sign_in_as(@admin_agent)
		tom_name = 'TOM Initial Fee equal to 0'
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		click_link_or_button 'Add New Plan'

		fill_in_step_1(tom_name)
		click_link_or_button 'Define Membership Terms'
		fill_in_step_2({initial_fee_amount:0, trial_period_amount:0, trial_period_lasting:0, installment_amount:0, installment_amount_days:1})
		click_link_or_button 'Define Upgrades / Downgrades'
		
		find("label", :text => "If we cannot bill an user then")
	  choose('if_cannot_bill_user_cancel')
		click_link_or_button 'Create Plan'
		assert page.has_content?('was created succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end

	test "Create subcription plan with Free Trial Period in Days" do
		sign_in_as(@admin_agent)
		tom_name = 'TOM Trial Period in Days'
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		click_link_or_button 'Add New Plan'

		fill_in_step_1(tom_name)
		click_link_or_button 'Define Membership Terms'
		fill_in_step_2({initial_fee_amount:0, trial_period_amount:0, trial_period_lasting:0, installment_amount:0, installment_amount_days:1})
		click_link_or_button 'Define Upgrades / Downgrades'

		find("label", :text => "If we cannot bill an user then")
		choose('if_cannot_bill_user_cancel')
		click_link_or_button 'Create Plan'
		assert page.has_content?('was created succesfully') # TOM was created
	end

	test "Create subcription plan with Free Trial Period in Months" do
		sign_in_as(@admin_agent)
		tom_name = 'TOM Trial Period in Months'
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		click_link_or_button 'Add New Plan'

		fill_in_step_1(tom_name)
		click_link_or_button 'Define Membership Terms'
		fill_in_step_2({initial_fee_amount:0, trial_period_amount:0, trial_period_lasting:0, installment_amount:0, installment_amount_days:1},{trial_period_lasting_time_span:"Month(s)"})
		click_link_or_button 'Define Upgrades / Downgrades'
		
		find("label", :text => "If we cannot bill an user then")
		choose('if_cannot_bill_user_cancel')
		click_link_or_button 'Create Plan'
		assert page.has_content?('was created succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end

	test "Create subcription plan with Paid Trial Period in Days" do
		sign_in_as(@admin_agent)
		tom_name = 'TOM with Paid Trial Period in Days'
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		click_link_or_button 'Add New Plan'
		
		fill_in_step_1(tom_name)
		click_link_or_button 'Define Membership Terms'
		fill_in_step_2({initial_fee_amount:0, trial_period_amount:100, trial_period_lasting:5, installment_amount:0, installment_amount_days:1},{trial_period_lasting_time_span:"Day(s)"})
		click_link_or_button 'Define Upgrades / Downgrades'

		find("label", :text => "If we cannot bill an user then")
		choose('if_cannot_bill_user_cancel')
		click_link_or_button 'Create Plan'
		assert page.has_content?('was created succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end

	test "Create subcription plan with Paid Trial Period in Months" do
		sign_in_as(@admin_agent)
		tom_name = 'TOM with Paid Trial Period in Months'
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		click_link_or_button 'Add New Plan'
		
		fill_in_step_1(tom_name)
		click_link_or_button 'Define Membership Terms'
		fill_in_step_2({initial_fee_amount:0, trial_period_amount:100, trial_period_lasting:5, installment_amount:0, installment_amount_days:1},{trial_period_lasting_time_span:"Month(s)"})
		click_link_or_button 'Define Upgrades / Downgrades'

		find("label", :text => "If we cannot bill an user then")
		choose('if_cannot_bill_user_cancel')
		click_link_or_button 'Create Plan'
		assert page.has_content?('was created succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end

	test "Create subcription plan with Recurring Amount in Months" do
		sign_in_as(@admin_agent)
		tom_name = 'TOM with Recurring Amount in Months'
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		click_link_or_button 'Add New Plan'

		fill_in_step_1(tom_name)
		click_link_or_button 'Define Membership Terms'
		fill_in_step_2({initial_fee_amount:0, trial_period_amount:0, trial_period_lasting:0, installment_amount:10, installment_amount_days:1},{installment_amount_days_time_span:"Month(s)"})
		click_link_or_button 'Define Upgrades / Downgrades'

		find("label", :text => "If we cannot bill an user then")
		choose('if_cannot_bill_user_cancel')
		click_link_or_button 'Create Plan'
		assert page.has_content?('was created succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end

	test "Create subcription plan with Recurring Amount in Years" do
		sign_in_as(@admin_agent)
		tom_name = 'TOM with Recurring Amount in Years'
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		click_link_or_button 'Add New Plan'

		fill_in_step_1(tom_name)
		click_link_or_button 'Define Membership Terms'
		fill_in_step_2({initial_fee_amount:0, trial_period_amount:0, trial_period_lasting:0, installment_amount:10, installment_amount_days:12},{installment_amount_days_time_span:"Month(s)"})
		click_link_or_button 'Define Upgrades / Downgrades'

		find("label", :text => "If we cannot bill an user then")
		choose('if_cannot_bill_user_cancel')
		click_link_or_button 'Create Plan'
		assert page.has_content?('was created succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end

	# Create an user with TOM before created
	test "Create a TOM with 'no payment is expected' selected - with Trial Period and Initial Club cash" do
		sign_in_as(@admin_agent)
		tom_name = 'TOM with No payment expected'
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		click_link_or_button 'Add New Plan'

		fill_in_step_1(tom_name)
		click_link_or_button 'Define Membership Terms'
		fill_in_step_2({initial_fee_amount:0, trial_period_amount:1, trial_period_lasting:1, terms_of_membership_initial_club_cash_amount:20},{},["is_payment_expected_no"])
		assert page.has_content? I18n.t('activerecord.attributes.terms_of_membership.wizard.keep_active_until_manually_cancelled')

		click_link_or_button 'Define Upgrades / Downgrades'
		click_link_or_button 'Create Plan'
		assert page.has_content?('was created succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table

		@terms_of_membership = TermsOfMembership.find_by_name tom_name
    unsaved_user =  FactoryGirl.build(:active_user, :club_id => @terms_of_membership.club_id)
    credit_card = FactoryGirl.build(:credit_card_master_card)
    enrollment_info = FactoryGirl.build(:enrollment_info)
    create_user_by_sloop(@admin_agent, unsaved_user, credit_card, enrollment_info, @terms_of_membership)

    saved_user = User.find_by_email unsaved_user.email

    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => saved_user.id)
    within("#table_membership_information") do
      within("#td_mi_club_cash_amount") { assert page.has_content?(@terms_of_membership.initial_club_cash_amount) }
    	assert page.has_content? I18n.t('activerecord.attributes.user.billing_is_not_expected')
    end
    assert_nil saved_user.next_retry_bill_date
	end

	#Create an user with TOM before created
	test "Create a TOM with 'no payment is expected' selected - with Trial Period and NOT Initial Club Cash" do
		sign_in_as(@admin_agent)
		tom_name = 'TOM with No payment expected'
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		click_link_or_button 'Add New Plan'

		fill_in_step_1(tom_name)
		click_link_or_button 'Define Membership Terms'
		fill_in_step_2({initial_fee_amount:0, trial_period_amount:1, trial_period_lasting:1},{},["is_payment_expected_no"])
		assert page.has_content? I18n.t('activerecord.attributes.terms_of_membership.wizard.keep_active_until_manually_cancelled')

		click_link_or_button 'Define Upgrades / Downgrades'
		click_link_or_button 'Create Plan'
		assert page.has_content?('was created succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table

		@terms_of_membership = TermsOfMembership.find_by_name tom_name
    unsaved_user =  FactoryGirl.build(:active_user, :club_id => @terms_of_membership.club_id)
    credit_card = FactoryGirl.build(:credit_card_master_card)
    enrollment_info = FactoryGirl.build(:enrollment_info)
    create_user_by_sloop(@admin_agent, unsaved_user, credit_card, enrollment_info, @terms_of_membership)

    saved_user = User.find_by_email unsaved_user.email

    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => saved_user.id)
    within("#table_membership_information") do
      within("#td_mi_club_cash_amount") { assert page.has_content?("0") }
    	assert page.has_content? I18n.t('activerecord.attributes.user.billing_is_not_expected')
    end
    assert_nil saved_user.next_retry_bill_date
	end

	# Create an user with TOM before created
	test "Create a TOM with 'no payment is expected' selected - without Trial Period and Initial Club Cash" do
		sign_in_as(@admin_agent)
		tom_name = 'TOM with No payment expected'
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		click_link_or_button 'Add New Plan'

		fill_in_step_1(tom_name)
		click_link_or_button 'Define Membership Terms'
		fill_in_step_2({initial_fee_amount:0, trial_period_amount:1, trial_period_lasting:0, terms_of_membership_initial_club_cash_amount:20},{},["is_payment_expected_no"])
		assert page.has_content? I18n.t('activerecord.attributes.terms_of_membership.wizard.keep_active_until_manually_cancelled')

		click_link_or_button 'Define Upgrades / Downgrades'
		click_link_or_button 'Create Plan'
		assert page.has_content?('was created succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table

		@terms_of_membership = TermsOfMembership.find_by_name tom_name
    unsaved_user =  FactoryGirl.build(:active_user, :club_id => @terms_of_membership.club_id)
    credit_card = FactoryGirl.build(:credit_card_master_card)
    enrollment_info = FactoryGirl.build(:enrollment_info)
    create_user_by_sloop(@admin_agent, unsaved_user, credit_card, enrollment_info, @terms_of_membership)

    saved_user = User.find_by_email unsaved_user.email

    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => saved_user.id)
    within("#table_membership_information") do
      within("#td_mi_club_cash_amount") { assert page.has_content?(@terms_of_membership.initial_club_cash_amount) }
    	assert page.has_content? I18n.t('activerecord.attributes.user.billing_is_not_expected')
    end
    assert_nil saved_user.next_retry_bill_date
	end

	# Create an user with TOM before created
	test "Create a TOM with 'no payment is expected' selected - without Trial Period and without Initial Club Cash" do
		sign_in_as(@admin_agent)
		tom_name = 'TOM with No payment expected'
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		click_link_or_button 'Add New Plan'

		fill_in_step_1(tom_name)
		click_link_or_button 'Define Membership Terms'
		fill_in_step_2({initial_fee_amount:0, trial_period_amount:1, trial_period_lasting:0},{},["is_payment_expected_no"])
		assert page.has_content? I18n.t('activerecord.attributes.terms_of_membership.wizard.keep_active_until_manually_cancelled')

		click_link_or_button 'Define Upgrades / Downgrades'
		click_link_or_button 'Create Plan'
		assert page.has_content?('was created succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table

		@terms_of_membership = TermsOfMembership.find_by_name tom_name
    unsaved_user =  FactoryGirl.build(:active_user, :club_id => @terms_of_membership.club_id)
    credit_card = FactoryGirl.build(:credit_card_master_card)
    enrollment_info = FactoryGirl.build(:enrollment_info)
    create_user_by_sloop(@admin_agent, unsaved_user, credit_card, enrollment_info, @terms_of_membership)

    saved_user = User.find_by_email unsaved_user.email

    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => saved_user.id)
    within("#table_membership_information") do
      within("#td_mi_club_cash_amount") { assert page.has_content?("0") }
    	assert page.has_content? I18n.t('activerecord.attributes.user.billing_is_not_expected')
    end
    assert_nil saved_user.next_retry_bill_date
	end

	# # test "Create subcription plan with Stop billing after at Subscription Terms - month" do
	# # 	tom_name = 'TOM with with Stop billing after Months'
	# # 	visit terms_of_memberships_path(@partner.prefix, @club.name)
	# # 	click_link_or_button 'Add New Plan'

	# # 	fill_in_step_1(tom_name)
	# # 	click_link_or_button 'Define Membership Terms'
	# # 	fill_in_step_2({initial_fee_amount:0, trial_period_amount:1, trial_period_lasting:0, installment_amount:1, installment_amount_days:1,subscription_terms_stop_billing_after:0},{subscription_terms_stop_billing_after_time_span:"Month(s)"},["subscription_terms_stop_cancel_after"])
	# # 	click_link_or_button 'Define Upgrades / Downgrades'

	# # 	find("label", :text => "If we cannot bill an user then")
	# # 	choose('if_cannot_bill_user_cancel')
	# # 	click_link_or_button 'Create Plan'
	# # 	assert page.has_content?('was created succesfully') # TOM was created
	# # 	assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	# # end

	# # test "Create subcription plan with Stop billing after at Subscription Terms - days" do
	# # 	tom_name = 'TOM with with Stop billing after Days'
	# # 	visit terms_of_memberships_path(@partner.prefix, @club.name)
	# # 	click_link_or_button 'Add New Plan'

	# # 	fill_in_step_1(tom_name)
	# # 	click_link_or_button 'Define Membership Terms'
	# # 	fill_in_step_2({initial_fee_amount:0, trial_period_amount:1, trial_period_lasting:0, installment_amount:1, installment_amount_days:1,subscription_terms_stop_billing_after:0},{subscription_terms_stop_billing_after_time_span:"Day(s)"},["subscription_terms_stop_cancel_after"])
	# # 	click_link_or_button 'Define Upgrades / Downgrades'

	# # 	find("label", :text => "If we cannot bill an user then")
	# # 	choose('if_cannot_bill_user_cancel')
	# # 	click_link_or_button 'Create Plan'
	# # 	assert page.has_content?('was created succesfully') # TOM was created
	# # 	assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	# # end

	test "Create an user at TOM created by Subscription Plan" do
		sign_in_as(@admin_agent)
		# First, create the TOM
		tom_name = 'TOM To Create the User'
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		click_link_or_button 'Add New Plan'
		
		fill_in_step_1(tom_name)
		click_link_or_button 'Define Membership Terms'
		fill_in_step_2({initial_fee_amount:1, trial_period_amount:0, trial_period_lasting:0, installment_amount:0, installment_amount_days:1})
		click_link_or_button 'Define Upgrades / Downgrades'
		
		find("label", :text => "If we cannot bill an user then")
	  choose('if_cannot_bill_user_cancel')
		click_link_or_button 'Create Plan'
		assert page.has_content?('was created succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
		# Then, create the user
		the_tom = TermsOfMembership.last
		the_user = create_active_user(the_tom, :active_user, nil, {}, { :created_by => @admin_agent })
		visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => the_user.id)
		assert page.find('#table_membership_information').has_content?(tom_name) # TOM is in the table
	end

	# test "Create subcription plan with Suspend for by days" do
	# 	tom_name = 'TOM with Suspend Days'
	# 	visit terms_of_memberships_path(@partner.prefix, @club.name)
	# 	click_link_or_button 'Add New Plan'
		
	# 	fill_in_step_1(tom_name)
	# 	click_link_or_button 'Define Membership Terms'
	# 	fill_in_step_2({initial_fee_amount:1, trial_period_amount:0, trial_period_lasting:0, installment_amount:10, installment_amount_days:1},{installment_amount_days_time_span:"Month(s)"})
	# 	click_link_or_button 'Define Upgrades / Downgrades'
		
	# 	find("label", :text => "If we cannot bill an user then")
	# 	choose('if_cannot_bill_user_suspend')
	# 	fill_in 'if_cannot_bill_user_suspend_for', :with => '30'
	# 	select('Day(s)', :from => 'if_cannot_bill_user_suspend_for_time_span')
	# 	click_link_or_button 'Create Plan'
	# 	assert page.has_content?('was created succesfully') # TOM was created
	# 	assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	# end

	# test "Create subcription plan with Suspend for by months" do
	# 	tom_name = 'TOM with Suspend Months'
	# 	visit terms_of_memberships_path(@partner.prefix, @club.name)
	# 	click_link_or_button 'Add New Plan'

	# 	fill_in_step_1(tom_name)
	# 	click_link_or_button 'Define Membership Terms'
	# 	fill_in_step_2({initial_fee_amount:1, trial_period_amount:0, trial_period_lasting:0, installment_amount:10, installment_amount_days:1},{installment_amount_days_time_span:"Month(s)"})
	# 	click_link_or_button 'Define Upgrades / Downgrades'
		
	# 	find("label", :text => "If we cannot bill an user then")
	# 	choose('if_cannot_bill_user_suspend')
	# 	fill_in 'if_cannot_bill_user_suspend_for', :with => '1'
	# 	select('Month(s)', :from => 'if_cannot_bill_user_suspend_for_time_span')
	# 	click_link_or_button 'Create Plan'
	# 	assert page.has_content?('was created succesfully') # TOM was created
	# 	assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	# end

	test "Create subcription plan with Downgrade to option" do
		sign_in_as(@admin_agent)
		tom_to_downgrade = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
		tom_name = 'TOM with Downgrade To'
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		click_link_or_button 'Add New Plan'

		fill_in_step_1(tom_name)
		click_link_or_button 'Define Membership Terms'
		fill_in_step_2({initial_fee_amount:1, trial_period_amount:0, trial_period_lasting:0, installment_amount:10, installment_amount_days:1},{installment_amount_days_time_span:"Month(s)"})
		click_link_or_button 'Define Upgrades / Downgrades'
		
		find("label", :text => "If we cannot bill an user then")
		choose('if_cannot_bill_user_downgrade_to')
		select(tom_to_downgrade.name, :from => 'downgrade_to_tom')
		click_link_or_button 'Create Plan'
		assert page.has_content?('was created succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end

	test "Create a new TOM with club cash and enroll an user with it" do
		sign_in_as(@admin_agent)
		tom_name = 'TOM Name with club cash'
		initial_amount_of_club_cash = 80
		club_cash_installment_amount = 100
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		click_link_or_button 'Add New Plan'

		fill_in_step_1(tom_name)
		click_link_or_button 'Define Membership Terms'
		fill_in_step_2({initial_fee_amount:1, trial_period_amount:0, trial_period_lasting:0, installment_amount:0, installment_amount_days:1, terms_of_membership_initial_club_cash_amount:initial_amount_of_club_cash, terms_of_membership_club_cash_installment_amount:club_cash_installment_amount})
		click_link_or_button 'Define Upgrades / Downgrades'

		find_button("Create Plan")
	  choose('if_cannot_bill_user_cancel')
		click_link_or_button 'Create Plan'
		assert page.has_content?('was created succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table

		@terms_of_membership = TermsOfMembership.find_by_name tom_name
		unsaved_user =  FactoryGirl.build(:active_user, :club_id => @terms_of_membership.club_id)
		credit_card = FactoryGirl.build(:credit_card_master_card)
		enrollment_info = FactoryGirl.build(:enrollment_info)
		create_user_by_sloop(@admin_agent, unsaved_user, credit_card, enrollment_info, @terms_of_membership)
		@saved_user = User.find_by_email(unsaved_user.email)  
		visit show_user_path(:partner_prefix => @terms_of_membership.club.partner.prefix, :club_prefix => @terms_of_membership.club.name, :user_prefix => @saved_user.id)
		within("#td_mi_club_cash_amount") { assert page.has_content?(initial_amount_of_club_cash) }
	end

	test "Create an user with TOM upgrate to = 1" do
		sign_in_as(@admin_agent)
		tom_name = 'TOM Name with upgrade'
		tom_to_upgrade = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id, :name => 'Upgraded TOM')

		visit terms_of_memberships_path(@partner.prefix, @club.name)
		click_link_or_button 'Add New Plan'

		fill_in_step_1(tom_name)
		click_link_or_button 'Define Membership Terms'
		fill_in_step_2({initial_fee_amount:1, trial_period_amount:0, trial_period_lasting:0, installment_amount:0, installment_amount_days:1})
		click_link_or_button 'Define Upgrades / Downgrades'

		select(tom_to_upgrade.name, :from => "upgrade_to_tom")
		fill_in "upgrade_to_tom_days", :with => "1"

		find_button("Create Plan")
	  choose('if_cannot_bill_user_cancel')
		click_link_or_button 'Create Plan'
		assert page.has_content?('was created succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table

		@terms_of_membership = TermsOfMembership.find_by_name tom_name
		unsaved_user =  FactoryGirl.build(:active_user, :club_id => @terms_of_membership.club_id)
		credit_card = FactoryGirl.build(:credit_card_master_card)
		enrollment_info = FactoryGirl.build(:enrollment_info)
		create_user_by_sloop(@admin_agent, unsaved_user, credit_card, enrollment_info, @terms_of_membership)
		@saved_user = User.find_by_email(unsaved_user.email)  
		visit show_user_path(:partner_prefix => @terms_of_membership.club.partner.prefix, :club_prefix => @terms_of_membership.club.name, :user_prefix => @saved_user.id)
	end

	# # EDIT

	test "Edit subcription plan with Initial Fee distinct of 0 - No membership associated" do
		sign_in_as(@admin_agent)
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
		
		find("label", :text => "If we cannot bill an user then")
		choose('if_cannot_bill_user_cancel')
		click_link_or_button 'Update Plan'
		assert page.has_content?('was updated succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end

	test "Edit subcription plan with Initial Fee at 0 - No membership associated" do
		sign_in_as(@admin_agent)
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

		find("label", :text => "If we cannot bill an user then")
		choose('if_cannot_bill_user_cancel')
		click_link_or_button 'Update Plan'
		assert page.has_content?('was updated succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end

	test "Update subcription plan with Free Trial Period by days - No membership associated" do
		sign_in_as(@admin_agent)
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
		
		find("label", :text => "If we cannot bill an user then")
		choose('if_cannot_bill_user_cancel')
		click_link_or_button 'Update Plan'
		assert page.has_content?('was updated succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end

	test "Update subcription plan with Free Trial Period by months - No membership associated" do
		sign_in_as(@admin_agent)
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
		
		find("label", :text => "If we cannot bill an user then")
		choose('if_cannot_bill_user_cancel')
		choose('if_cannot_bill_user_cancel')
		click_link_or_button 'Update Plan'
		assert page.has_content?('was updated succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end

	test "Update subcription plan with Paid Trial Period by days - No membership associated" do
		sign_in_as(@admin_agent)
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
		
		find("label", :text => "If we cannot bill an user then")
		choose('if_cannot_bill_user_cancel')
		click_link_or_button 'Update Plan'
		assert page.has_content?('was updated succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end

	test "Update subcription plan with Paid Trial Period by month - No membership associated" do
		sign_in_as(@admin_agent)
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
		
		find("label", :text => "If we cannot bill an user then")
		choose('if_cannot_bill_user_cancel')
		click_link_or_button 'Update Plan'
		assert page.has_content?('was updated succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end

	test "Update subcription plan with Recurring Amount by month - No membership associated" do
		sign_in_as(@admin_agent)
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
		
		find("label", :text => "If we cannot bill an user then")
		choose('if_cannot_bill_user_cancel')
		click_link_or_button 'Update Plan'
		assert page.has_content?('was updated succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end

	test "Update subcription plan with Recurring Amount by year - No membership associated" do
		sign_in_as(@admin_agent)
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
		
		find("label", :text => "If we cannot bill an user then")
		choose('if_cannot_bill_user_cancel')
		click_link_or_button 'Update Plan'
		assert page.has_content?('was updated succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end

	test "Update subcription plan with No payment is expected - No membership associated" do
		sign_in_as(@admin_agent)
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
		
		first("div", I18n.t('activerecord.attributes.terms_of_membership.wizard.no_downgrade_upgrade_configuration'))
		click_link_or_button 'Update Plan'
		assert page.has_content?('was updated succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end

	# test "Update subcription plan with Stop billing after at Subscription Terms - month  - No membership associated" do
	# 	tom_name = 'TOM Name'
	# 	tom = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id, :name => tom_name)
	# 	visit terms_of_memberships_path(@partner.prefix, @club.name)
	# 	within('#terms_of_memberships_table') do
	# 		find('.sorting_asc', :text => 'ID').click # Sorting desc to show the last tom we had created as the first row of the table
	# 		within("tr", :text => tom_name) do
	# 			click_link_or_button "Edit"
	# 		end
	# 	end

	# 	fill_in_step_1(tom_name + ' Updated')
	# 	click_link_or_button 'Edit Membership Terms'
	# 	fill_in_step_2({initial_fee_amount:10, trial_period_amount:20, trial_period_lasting:30, installment_amount:10, installment_amount_days:24},{subscription_terms_stop_billing_after_time_span:"Month(s)",installment_amount_days_time_span:"Month(s)"},["is_payment_expected_yes","subscription_terms_stop_cancel_after"])
	# 	click_link_or_button 'Edit Upgrades / Downgrades'
		
	# 	find("label", :text => "If we cannot bill an user then")
	# 	choose('if_cannot_bill_user_cancel')
	# 	click_link_or_button 'Update Plan'
	# 	assert page.has_content?('was updated succesfully') # TOM was created
	# 	assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	# end

	# test "Update subcription plan with Stop billing after at Subscription Terms - day - No membership associated" do
	# 	tom_name = 'TOM Name'
	# 	tom = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id, :name => tom_name)
	# 	visit terms_of_memberships_path(@partner.prefix, @club.name)
	# 	within('#terms_of_memberships_table') do
	# 		find('.sorting_asc', :text => 'ID').click # Sorting desc to show the last tom we had created as the first row of the table
	# 		within("tr", :text => tom_name) do
	# 			click_link_or_button "Edit"
	# 		end
	# 	end

	# 	fill_in_step_1(tom_name + ' Updated')
	# 	click_link_or_button 'Edit Membership Terms'
	# 	fill_in_step_2({initial_fee_amount:10, trial_period_amount:20, trial_period_lasting:30, installment_amount:10, installment_amount_days:24, subscription_terms_stop_billing_after:10},{installment_amount_days_time_span:"Month(s)",subscription_terms_stop_billing_after_time_span:"Day(s)"},["is_payment_expected_yes","subscription_terms_stop_cancel_after"])
	# 	click_link_or_button 'Edit Upgrades / Downgrades'
		
	# 	find("label", :text => "If we cannot bill an user then")
	# 	choose('if_cannot_bill_user_cancel')
	# 	click_link_or_button 'Update Plan'
	# 	assert page.has_content?('was updated succesfully') # TOM was created
	# 	assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	# end

	# test "Create an user at TOM updated by Subscription Plan  - No membership associated" do
	# 	# First, create the TOM and update it
	# 	tom_name = 'TOM Name'
	# 	tom = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id, :name => tom_name)
	# 	visit terms_of_memberships_path(@partner.prefix, @club.name)
	# 	within('#terms_of_memberships_table') do
	# 		find('.sorting_asc', :text => 'ID').click # Sorting desc to show the last tom we had created as the first row of the table
	# 		within("tr", :text => tom_name) do
	# 			click_link_or_button "Edit"
	# 		end
	# 	end

	# 	fill_in_step_1(tom_name + ' Updated')
	# 	click_link_or_button 'Edit Membership Terms'
	# 	fill_in_step_2({initial_fee_amount:10, trial_period_amount:20, trial_period_lasting:30, 
	# 		              installment_amount:10, installment_amount_days:24, subscription_terms_stop_billing_after:10},
	# 							   {installment_amount_days_time_span: 'Month(s)', subscription_terms_stop_billing_after_time_span: "Day(s)"},
	# 	               ["is_payment_expected_yes", "subscription_terms_stop_cancel_after"])
	# 	click_link_or_button 'Edit Upgrades / Downgrades'
		
	# 	find("label", :text => "If we cannot bill an user then")
	# 	choose('if_cannot_bill_user_suspend')
	# 	fill_in 'if_cannot_bill_user_suspend_for', :with => '10'
	# 	select('Day(s)', :from => 'if_cannot_bill_user_suspend_for_time_span')
	# 	click_link_or_button 'Update Plan'
	# 	# Then, create the user
	# 	the_tom = TermsOfMembership.last
	# 	the_user = create_active_user(the_tom, :active_user, nil, {}, { :created_by => @admin_agent })
	# 	visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => the_user.id)
	# 	assert page.find('#table_membership_information').has_content?(tom_name) # TOM is in the table
	# end

	# test "Update subcription plan with Suspend for by days - No membership associated" do
	# 	tom_name = 'TOM Name'
	# 	tom = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id, :name => tom_name)
	# 	visit terms_of_memberships_path(@partner.prefix, @club.name)
	# 	within('#terms_of_memberships_table') do
	# 		find('.sorting_asc', :text => 'ID').click # Sorting desc to show the last tom we had created as the first row of the table
	# 		within("tr", :text => tom_name) do
	# 			click_link_or_button "Edit"
	# 		end
	# 	end

	# 	fill_in_step_1(tom_name + ' Updated')
	# 	click_link_or_button 'Edit Membership Terms'
	# 	fill_in_step_2({initial_fee_amount:10, trial_period_amount:20, trial_period_lasting:30, 
	# 		              installment_amount:10, installment_amount_days:24, subscription_terms_stop_billing_after:10},
	# 							   {installment_amount_days_time_span: 'Month(s)', subscription_terms_stop_billing_after_time_span: "Day(s)"},
	# 	               ["is_payment_expected_yes", "subscription_terms_stop_cancel_after"])
	# 	click_link_or_button 'Edit Upgrades / Downgrades'
		
	# 	find("label", :text => "If we cannot bill an user then")
	# 	choose('if_cannot_bill_user_suspend')
	# 	fill_in 'if_cannot_bill_user_suspend_for', :with => '10'
	# 	select('Day(s)', :from => 'if_cannot_bill_user_suspend_for_time_span')
	# 	click_link_or_button 'Update Plan'
	# 	assert page.has_content?('was updated succesfully') # TOM was created
	# 	assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	# end

	# test "Update subcription plan with Suspend for by month - No membership associated" do
	# 	tom_name = 'TOM Name'
	# 	tom = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id, :name => tom_name)
	# 	visit terms_of_memberships_path(@partner.prefix, @club.name)
	# 	within('#terms_of_memberships_table') do
	# 		find('.sorting_asc', :text => 'ID').click # Sorting desc to show the last tom we had created as the first row of the table
	# 		within("tr", :text => tom_name) do
	# 			click_link_or_button "Edit"
	# 		end
	# 	end

	# 	fill_in_step_1(tom_name + ' Updated')
	# 	click_link_or_button 'Edit Membership Terms'
	# 	fill_in_step_2({initial_fee_amount:10, trial_period_amount:20, trial_period_lasting:30, 
	# 		              installment_amount:10, installment_amount_days:24, subscription_terms_stop_billing_after:1},
	# 							   {installment_amount_days_time_span: 'Month(s)', subscription_terms_stop_billing_after_time_span: "Month(s)"},
	# 	               ["is_payment_expected_yes", "subscription_terms_stop_cancel_after"])
	# 	click_link_or_button 'Edit Upgrades / Downgrades'
		
	# 	find("label", :text => "If we cannot bill an user then")
	# 	choose('if_cannot_bill_user_suspend')
	# 	fill_in 'if_cannot_bill_user_suspend_for', :with => '10'
	# 	select('Month(s)', :from => 'if_cannot_bill_user_suspend_for_time_span')
	# 	click_link_or_button 'Update Plan'
	# 	assert page.has_content?('was updated succesfully') # TOM was created
	# 	assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	# end

	# test "Create subcription plan with Downgrade to option - No membership associated" do
	# 	tom_name = 'TOM Name'
	# 	tom = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id, :name => tom_name)
	# 	tom_to_downgrade = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id, :name => 'Downgradable TOM')
	# 	visit terms_of_memberships_path(@partner.prefix, @club.name)
	# 	within('#terms_of_memberships_table') do
	# 		find('.sorting_asc', :text => 'ID').click # Sorting desc to show the last tom we had created as the first row of the table
	# 		within("tr", :text => tom_name) do
	# 			click_link_or_button "Edit"
	# 		end
	# 	end

	# 	fill_in_step_1(tom_name + ' Updated')
	# 	click_link_or_button 'Edit Membership Terms'
	# 	fill_in_step_2({initial_fee_amount:10, trial_period_amount:20, trial_period_lasting:30, 
	# 		              installment_amount:10, installment_amount_days:24, subscription_terms_stop_billing_after:10},
	# 							   {installment_amount_days_time_span: 'Month(s)', subscription_terms_stop_billing_after_time_span: "Day(s)"},
	# 	               ["is_payment_expected_yes", "subscription_terms_stop_cancel_after"])
	# 	click_link_or_button 'Edit Upgrades / Downgrades'
		
	# 	find("label", :text => "If we cannot bill an user then")
	# 	choose('if_cannot_bill_user_downgrade_to')
	# 	select(tom_to_downgrade.name, :from => 'downgrade_to_tom')
	# 	click_link_or_button 'Update Plan'
	# 	assert page.has_content?('was updated succesfully') # TOM was created
	# 	assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	# end

	test "Update subcription plan with external code and description - No membership associated" do
		sign_in_as(@admin_agent)
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
								   {installment_amount_days_time_span: 'Month(s)'},
					   ["is_payment_expected_yes", "subscription_terms_until_cancelled"])
		click_link_or_button 'Edit Upgrades / Downgrades'
		
		find("label", :text => "If we cannot bill an user then")
		choose('if_cannot_bill_user_cancel')
		click_link_or_button 'Update Plan'
		assert page.has_content?('was updated succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end

	test "Do not edit TOM with active (active, applied and provisional) membership" do
		sign_in_as(@admin_agent)
		27.times { |n| the_tom = FactoryGirl.create(:terms_of_membership_with_gateway, :name => "test#{n}" ,:club_id => @club.id) }
		the_tom = TermsOfMembership.last
		the_user = create_active_user(the_tom, :active_user, nil, {}, { :created_by => @admin_agent })
			visit terms_of_memberships_path(@partner.prefix, @club.name)
		within('#terms_of_memberships_table') do
			find('.sorting_asc', :text => 'ID').click # Sorting desc to show the last tom we had created as the first row of the table
			within("tr", :text => the_tom.name) do
				confirm_ok_js
				click_link_or_button "Edit"
			end
		end
		assert page.has_content?("can not be edited")
	end

	test "Do not edit TOM with inactive (lapsed) membership" do
		sign_in_as(@admin_agent)
		27.times { |n| the_tom = FactoryGirl.create(:terms_of_membership_with_gateway, :name => "test#{n}" ,:club_id => @club.id) }
		the_tom = TermsOfMembership.last
		the_lapsed_user = create_active_user(the_tom, :lapsed_user, nil, {}, { :created_by => @admin_agent })
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		within('#terms_of_memberships_table') do
			find('.sorting_asc', :text => 'ID').click # Sorting desc to show the last tom we had created as the first row of the table
			within("tr", :text => the_tom.name) do
				confirm_ok_js
				click_link_or_button "Edit"
			end
		end
		assert page.has_content?("can not be edited")
	end

	test "Edit TOM without users and add club cash" do
		sign_in_as(@admin_agent)
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
		fill_in_step_2({initial_fee_amount:1, trial_period_amount:0, trial_period_lasting:0, installment_amount:0, installment_amount_days:1, terms_of_membership_initial_club_cash_amount:100, terms_of_membership_club_cash_installment_amount:200})
		click_link_or_button 'Edit Upgrades / Downgrades'

		find_button("Update Plan")
		choose('if_cannot_bill_user_cancel')
		click_link_or_button 'Update Plan'
		assert page.has_content?('was updated succesfully') # TOM was updated
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end

	test "Delete club cash at TOM - TOM without users" do
		sign_in_as(@admin_agent)
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
		fill_in_step_2({initial_fee_amount:1, trial_period_amount:0, trial_period_lasting:0, installment_amount:0, installment_amount_days:1, terms_of_membership_initial_club_cash_amount:0, terms_of_membership_club_cash_installment_amount:0})
		click_link_or_button 'Edit Upgrades / Downgrades'

		find_button("Update Plan")
	  choose('if_cannot_bill_user_cancel')
		click_link_or_button 'Update Plan'
		assert page.has_content?('was updated succesfully') # TOM was updated
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
		tom.reload
		assert_equal tom.initial_club_cash_amount.to_i, 0
		assert_equal tom.club_cash_installment_amount.to_i, 0
	end

	test "Edit TOM without users and add club cash " do
		sign_in_as(@admin_agent)
		tom_name = 'TOM Name'
		initial_club_cash_amount = 50
		club_cash_installment_amount = 150
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
		fill_in_step_2({initial_fee_amount:1, trial_period_amount:0, trial_period_lasting:0, installment_amount:0, installment_amount_days:1, terms_of_membership_initial_club_cash_amount:initial_club_cash_amount, terms_of_membership_club_cash_installment_amount:club_cash_installment_amount})
		click_link_or_button 'Edit Upgrades / Downgrades'

		find_button("Update Plan")
	  choose('if_cannot_bill_user_cancel')
		click_link_or_button 'Update Plan'
		assert page.has_content?('was updated succesfully') # TOM was updated
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
		tom.reload
		assert_equal tom.initial_club_cash_amount.to_i, initial_club_cash_amount.to_i
		assert_equal tom.club_cash_installment_amount.to_i, club_cash_installment_amount.to_i
	end

	# # # # DELETE

	test "Delete unused TOM" do
		sign_in_as(@admin_agent)
		27.times { |n| the_tom = FactoryGirl.create(:terms_of_membership_with_gateway, :name => "test#{n}" ,:club_id => @club.id) }
		the_tom = TermsOfMembership.last
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		within('#terms_of_memberships_table') do
			find('.sorting_asc', :text => 'ID').click # Sorting desc to show the last tom we had created as the first row of the table
			within("tr", :text => the_tom.name) do
				confirm_ok_js
				click_link_or_button "Destroy"
			end
		end
		assert page.has_content?("was successfully destroyed.")
	end

	test "Do not delete a TOM with inactive memberships" do
		sign_in_as(@admin_agent)
		27.times { |n| the_tom = FactoryGirl.create(:terms_of_membership_with_gateway, :name => "test#{n}" ,:club_id => @club.id) }
		the_tom = TermsOfMembership.last
		the_lapsed_user = create_active_user(the_tom, :lapsed_user, nil, {}, { :created_by => @admin_agent })
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		within('#terms_of_memberships_table') do
			find('.sorting_asc', :text => 'ID').click # Sorting desc to show the last tom we had created as the first row of the table
			within("tr", :text => the_tom.name) do
				confirm_ok_js
				click_link_or_button "Destroy"
			end
		end
		assert page.has_content?("was not destroyed.")
	end

	test "Do not delete a TOM with active memberships" do
		sign_in_as(@admin_agent)
		27.times { |n| the_tom = FactoryGirl.create(:terms_of_membership_with_gateway, :name => "test#{n}" ,:club_id => @club.id) }
		the_tom = TermsOfMembership.last
		the_active_user = create_active_user(the_tom, :active_user, nil, {}, { :created_by => @admin_agent })
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		within('#terms_of_memberships_table') do
			find('.sorting_asc', :text => 'ID').click # Sorting desc to show the last tom we had created as the first row of the table
			within("tr", :text => the_tom.name) do
				confirm_ok_js
				click_link_or_button "Destroy"
			end
		end
		assert page.has_content?("was not destroyed.")
	end

	test "Create a TOM that Requires Approval" do
		sign_in_as(@admin_agent)
		tom_name = 'TOM that Requires Approval'
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		click_link_or_button 'Add New Plan'

		fill_in_step_1(tom_name)
		click_link_or_button 'Define Membership Terms'
		
		check('terms_of_membership_needs_enrollment_approval');
		choose('is_payment_expected_no')
		choose('subscription_terms_until_cancelled')
		click_link_or_button 'Define Upgrades / Downgrades'

		click_link_or_button 'Create Plan'

		assert page.has_content?('was created succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end


	test "Edit a TOM that doesn't Require Approval" do
		sign_in_as(@admin_agent)
		tom_name = 'TOM that doesnt Require Approval'
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

		check('terms_of_membership_needs_enrollment_approval');
		choose('is_payment_expected_no')
		choose('subscription_terms_until_cancelled')
		click_link_or_button 'Edit Upgrades / Downgrades'
		
		click_link_or_button 'Update Plan'

		assert page.has_content?('was updated succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end


	test "Edit a TOM that Requires Approval" do
		sign_in_as(@admin_agent)
		tom_name = 'TOM that Requires Approval'
		tom = FactoryGirl.create(:terms_of_membership_with_gateway_and_approval_required, :club_id => @club.id, :name => tom_name)
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		within('#terms_of_memberships_table') do
			find('.sorting_asc', :text => 'ID').click # Sorting desc to show the last tom we had created as the first row of the table
			within("tr", :text => tom_name) do
				click_link_or_button "Edit"
			end
		end

		fill_in_step_1(tom_name + ' Updated')
		click_link_or_button 'Edit Membership Terms'

		check('terms_of_membership_needs_enrollment_approval');
		choose('is_payment_expected_no')
		choose('subscription_terms_until_cancelled')
		click_link_or_button 'Edit Upgrades / Downgrades'
		
		click_link_or_button 'Update Plan'
		
		assert page.has_content?('was updated succesfully') # TOM was created
		assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
	end

	test "Delete a TOM that Requires Approval" do
		sign_in_as(@admin_agent)
		27.times { |n| the_tom = FactoryGirl.create(:terms_of_membership_with_gateway_and_approval_required, :name => "test#{n}" ,:club_id => @club.id) }
		the_tom = TermsOfMembership.last
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		within('#terms_of_memberships_table') do
			find('.sorting_asc', :text => 'ID').click # Sorting desc to show the last tom we had created as the first row of the table
			within("tr", :text => the_tom.name) do
				confirm_ok_js
				click_link_or_button "Destroy"
			end
		end
		assert page.has_content?("was successfully destroyed.")
	end

	test "Create an user a TOM that Requires Approval" do
		sign_in_as(@admin_agent)
		the_tom = FactoryGirl.create(:terms_of_membership_with_gateway_and_approval_required, :club_id => @club.id, :name => 'TOM that Requires Approval')
		unsaved_user =  FactoryGirl.build(:active_user, :club_id => the_tom.club_id)
		credit_card = FactoryGirl.build(:credit_card_master_card)
		enrollment_info = FactoryGirl.build(:enrollment_info)
		create_user_by_sloop(@admin_agent, unsaved_user, credit_card, enrollment_info, the_tom)
		@saved_user = User.find_by_email(unsaved_user.email)  
		visit show_user_path(:partner_prefix => the_tom.club.partner.prefix, :club_prefix => the_tom.club.name, :user_prefix => @saved_user.id)
	end
end
