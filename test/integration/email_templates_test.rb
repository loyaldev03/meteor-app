require 'test_helper'

class EmailTemplatesTest < ActionController::IntegrationTest
  setup do
    @admin_agent = FactoryGirl.create(:confirmed_admin_agent)
    @partner = FactoryGirl.create(:partner)
    @club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id)
    @tom = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id, :name => 'TOM for Email Templates Test')
    @communication = FactoryGirl.create(:email_template, :terms_of_membership_id => @tom.id)
  end

	def fill_in_form(options_for_texts = {}, options_for_selects = {}, options_for_checkboxs = [])
		options_for_checkboxs.each do |value|
			choose(value)
		end
		options_for_selects.each do |field, value|
			select(value, :from => field)
		end
		options_for_texts.each do |field, value|
			fill_in field, :with => value
		end
	end

	# test 'Show all member communications - Logged by General Admin' do
	# 	sign_in_as(@admin_agent)
	# 	visit terms_of_memberships_path(@partner.prefix, @club.name)
	# 	within('#terms_of_memberships_table') do
	# 		within("tr", :text => @tom.name) do
	# 			click_link_or_button "Communications"
	# 		end
	# 	end
	# 	assert page.has_content?('Communications')
 #  end

	# test 'Add member communications - Logged by General Admin' do
	# 	sign_in_as(@admin_agent)
	# 	visit terms_of_memberships_path(@partner.prefix, @club.name)
	# 	within('#terms_of_memberships_table') do
	# 		within("tr", :text => @tom.name) do
	# 			click_link_or_button "Communications"
	# 		end
	# 	end
	# 	click_link_or_button 'New Communication'
	# 	fill_in_form(
	# 		{email_template_name: 'Comm Name', trigger_id: 12345, mlid: 23456, site_id: 34567, customer_key: 45678}, 
	# 		{template_type: "Pillar", client: "Exact Target"}, [])
	# 	click_link_or_button 'Create Email template'

	# 	assert page.has_content?('was successfully created')
 #  end

	test 'Do not allow enter days_after_join_date = 0 - Logged by General Admin' do
		sign_in_as(@admin_agent)
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		within('#terms_of_memberships_table') do
			within("tr", :text => @tom.name) do
				click_link_or_button "Communications"
			end
		end
		click_link_or_button 'New Communication'
		begin
			fill_in_form(
				{email_template_name: 'Comm Name', trigger_id: 12345, mlid: 23456, site_id: 34567, customer_key: 45678, email_template_days_after_join_date: '0'}, 
				{template_type: "Pillar", client: "Exact Target"}, [])
			click_link_or_button 'Create Email template'
		rescue Exception => e
			assert page.has_content?('must be greater than or equal to 1')
		end
  end

	# test 'Show one member communication - Logged by General Admin' do
	# 	communication_name = 'Comm Name'
	# 	sign_in_as(@admin_agent)
	# 	visit terms_of_memberships_path(@partner.prefix, @club.name)
	# 	within('#terms_of_memberships_table') do
	# 		within("tr", :text => @tom.name) do
	# 			click_link_or_button "Communications"
	# 		end
	# 	end
	# 	click_link_or_button 'New Communication'
	# 	fill_in_form(
	# 		{email_template_name: communication_name, trigger_id: 12345, mlid: 23456, site_id: 34567, customer_key: 45678}, 
	# 		{template_type: "Pillar", client: "Exact Target"}, [])
	# 	click_link_or_button 'Create Email template'
	# 	@et = EmailTemplate.find(:last)
	# 	visit terms_of_membership_email_template_path(@partner.prefix, @club.name, @tom.id, @et.id)	
	# 	assert page.has_content?('General Information')
 #  end

	test 'Do not allow enter member communication duplicate where it is not Pillar type - Logged by General Admin' do
		old_comm = FactoryGirl.create(:email_template, :terms_of_membership_id => @tom.id, :template_type => 'birthday')
		old_comm.save
		sign_in_as(@admin_agent)
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		within('#terms_of_memberships_table') do
			within("tr", :text => @tom.name) do
				click_link_or_button "Communications"
			end
		end
		click_link_or_button 'New Communication'
		begin
			fill_in_form(
				{email_template_name: 'Comm Name', trigger_id: 12345, mlid: 23456, site_id: 34567, customer_key: 45678}, 
				{template_type: "Pillar", client: "Exact Target"}, [])
			within('#et_form') do
				page.has_no_select?('template_type', :with_options => ['Birthday'])
			end
		rescue Exception => e
			assert page.has_content?('must be greater than or equal to 1')
		end
		assert !page.has_content?('was successfully created')
	end

	# test 'Allow to create more than one member communication with Pillar type - Logged by General Admin' do
	# 	old_comm = FactoryGirl.create(:email_template, :terms_of_membership_id => @tom.id, :template_type => 'pillar')
	# 	old_comm.save
	# 	sign_in_as(@admin_agent)
	# 	visit terms_of_memberships_path(@partner.prefix, @club.name)
	# 	within('#terms_of_memberships_table') do
	# 		within("tr", :text => @tom.name) do
	# 			click_link_or_button "Communications"
	# 		end
	# 	end
	# 	click_link_or_button 'New Communication'
	# 	fill_in_form(
	# 		{email_template_name: 'Comm Name', trigger_id: 12345, mlid: 23456, site_id: 34567, customer_key: 45678}, 
	# 		{template_type: "Pillar", client: "Exact Target"}, [])
	# 	click_link_or_button 'Create Email template'
	# 	assert page.has_content?('was successfully created')
	# end


 #  test "Show all member communications - Logged by Admin_by_club" do
 #    @club_admin = FactoryGirl.create(:confirmed_admin_agent)
 #    club_role = ClubRole.new :club_id => @club.id
 #    club_role.agent_id = @club_admin.id
 #    club_role.role = "admin"
 #    club_role.save
 #    @club_admin.roles = nil
 #    @club_admin.save
 #    sign_in_as(@club_admin)
 #    @club_tom = FactoryGirl.create :terms_of_membership_with_gateway, :club_id => @club.id    
 #    @club_tom.save
	# 	visit terms_of_memberships_path(@partner.prefix, @club.name)
	# 	within('#terms_of_memberships_table') do
	# 		within("tr", :text => @tom.name) do
	# 			click_link_or_button "Communications"				
	# 		end
	# 	end
	# 	assert page.has_content?('Communications')
 #  end

	test 'Do not allow enter days_after_join_date = 0 - Logged by Admin_by_club' do
    @club_admin = FactoryGirl.create(:confirmed_admin_agent)
    club_role = ClubRole.new :club_id => @club.id
    club_role.agent_id = @club_admin.id
    club_role.role = "admin"
    club_role.save
    @club_admin.roles = nil
    @club_admin.save
    sign_in_as(@club_admin)
    @club_tom = FactoryGirl.create :terms_of_membership_with_gateway, :club_id => @club.id    
    @club_tom.save
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		within('#terms_of_memberships_table') do
			within("tr", :text => @tom.name) do
				click_link_or_button "Communications"
			end
		end
		click_link_or_button 'New Communication'
		begin
			fill_in_form(
				{email_template_name: 'Comm Name', trigger_id: 12345, mlid: 23456, site_id: 34567, customer_key: 45678, email_template_days_after_join_date: '0'}, 
				{template_type: "Pillar", client: "Exact Target"}, [])
			click_link_or_button 'Create Email template'
		rescue Exception => e
			assert page.has_content?('must be greater than or equal to 1')
		end
		assert !page.has_content?('was successfully created')
  end

	# test 'Add member communications - Logged by Admin_by_club' do
	# 	@club_admin = FactoryGirl.create(:confirmed_admin_agent)
 #    club_role = ClubRole.new :club_id => @club.id
 #    club_role.agent_id = @club_admin.id
 #    club_role.role = "admin"
 #    club_role.save
 #    @club_admin.roles = nil
 #    @club_admin.save
 #    sign_in_as(@club_admin)
 #    @club_tom = FactoryGirl.create :terms_of_membership_with_gateway, :club_id => @club.id    
 #    @club_tom.save
	# 	visit terms_of_memberships_path(@partner.prefix, @club.name)
	# 	within('#terms_of_memberships_table') do
	# 		within("tr", :text => @tom.name) do
	# 			click_link_or_button "Communications"
	# 		end
	# 	end
	# 	click_link_or_button 'New Communication'
	# 	fill_in_form(
	# 		{email_template_name: 'Comm Name', trigger_id: 12345, mlid: 23456, site_id: 34567, customer_key: 45678}, 
	# 		{template_type: "Pillar", client: "Exact Target"}, [])
	# 	click_link_or_button 'Create Email template'
	# 	assert page.has_content?('was successfully created')
 #  end

	# test 'Show one member communication - Logged by Admin_by_club' do
	# 	@club_admin = FactoryGirl.create(:confirmed_admin_agent)
 #    club_role = ClubRole.new :club_id => @club.id
 #    club_role.agent_id = @club_admin.id
 #    club_role.role = "admin"
 #    club_role.save
 #    @club_admin.roles = nil
 #    @club_admin.save
 #    sign_in_as(@club_admin)
 #    @club_tom = FactoryGirl.create :terms_of_membership_with_gateway, :club_id => @club.id    
 #    @club_tom.save
	# 	visit terms_of_memberships_path(@partner.prefix, @club.name)	
	# 	communication_name = 'Comm Name'
	# 	within('#terms_of_memberships_table') do
	# 		within("tr", :text => @tom.name) do
	# 			click_link_or_button "Communications"
	# 		end
	# 	end
	# 	click_link_or_button 'New Communication'
	# 	fill_in_form(
	# 		{email_template_name: communication_name, trigger_id: 12345, mlid: 23456, site_id: 34567, customer_key: 45678}, 
	# 		{template_type: "Pillar", client: "Exact Target"}, [])
	# 	click_link_or_button 'Create Email template'
	# 	@et = EmailTemplate.find(:last)
	# 	visit terms_of_membership_email_template_path(@partner.prefix, @club.name, @club_tom.id, @et.id)	
	# 	assert page.has_content?('General Information')
 #  end

	# test 'Do not allow enter member communication duplicate - Logged by Admin_by_club' do
	# 	@club_admin = FactoryGirl.create(:confirmed_admin_agent)
 #    club_role = ClubRole.new :club_id => @club.id
 #    club_role.agent_id = @club_admin.id
 #    club_role.role = "admin"
 #    club_role.save
 #    @club_admin.roles = nil
 #    @club_admin.save
 #    sign_in_as(@club_admin)
 #    @club_tom = FactoryGirl.create :terms_of_membership_with_gateway, :club_id => @club.id    
 #    @club_tom.save
	# 	visit terms_of_memberships_path(@partner.prefix, @club.name)	
	# 	old_comm = FactoryGirl.create(:email_template, :terms_of_membership_id => @tom.id, :template_type => 'birthday')
	# 	old_comm.save
	# 	within('#terms_of_memberships_table') do
	# 		within("tr", :text => @tom.name) do
	# 			click_link_or_button "Communications"
	# 		end
	# 	end
	# 	click_link_or_button 'New Communication'
	# 	fill_in_form(
	# 		{email_template_name: 'Comm Name', trigger_id: 12345, mlid: 23456, site_id: 34567, customer_key: 45678}, 
	# 		{template_type: "Pillar", client: "Exact Target"}, [])
	# 	within('#et_form') do
	# 		page.has_no_select?('template_type', :with_options => ['Birthday'])
	# 	end
	# end
















end