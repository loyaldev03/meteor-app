
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

	test 'Show all member communications - Logged by General Admin' do
		sign_in_as(@admin_agent)
		visit terms_of_memberships_path(@partner.prefix, @club.name)
    @tom2 = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id, :name => 'TOM for Email Templates Test2')
    communication = FactoryGirl.create(:email_template, :terms_of_membership_id => @tom2.id, :name => "EmailTemplateTest")
		within('#terms_of_memberships_table') do
			within("tr", :text => @tom.name) do
				click_link_or_button "Communications"
			end
		end
		assert page.has_content?('Communications')
		@tom.email_templates.each do |email_template|
			assert page.has_content? email_template.name
		end
		assert page.has_no_content? communication.name
  end

	test 'Add member communications - Logged by General Admin' do
		sign_in_as(@admin_agent)
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		within('#terms_of_memberships_table') do
			within("tr", :text => @tom.name) do
				click_link_or_button "Communications"
			end
		end
		click_link_or_button 'New Communication'
		fill_in_form(
			{email_template_name: 'Comm Name', customer_key: 45678}, 
			{"email_template[template_type]" => "Pillar", "email_template[client]" => "Exact Target"}, [])
		click_link_or_button 'Create Email template'

		assert page.has_content?('was successfully created')
  end

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
				{email_template_name: 'Comm Name', customer_key: 45678, email_template_days_after_join_date: '0'}, 
				{"email_template[template_type]" => "Pillar", "email_template[client]" => "Exact Target"}, [])
			click_link_or_button 'Create Email template'
		rescue Exception => e
			assert page.has_content?('must be greater than or equal to 1')
		end
  end

	test 'Show one member communication - Logged by General Admin' do
		communication_name = 'Comm Name'
		sign_in_as(@admin_agent)
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		within('#terms_of_memberships_table') do
			within("tr", :text => @tom.name) do
				click_link_or_button "Communications"
			end
		end
		click_link_or_button 'New Communication'
		fill_in_form(
			{email_template_name: communication_name, customer_key: 45678}, 
			{"email_template[template_type]" => "Pillar", "email_template[client]" => "Exact Target"}, [])
		click_link_or_button 'Create Email template'
		@et = EmailTemplate.find(:last)
		visit terms_of_membership_email_template_path(@partner.prefix, @club.name, @tom.id, @et.id)	
		assert page.has_content?('General Information')
  end

	test 'Allow to create more than one member communication with Pillar type - Logged by General Admin' do
		old_comm = FactoryGirl.create(:email_template, :terms_of_membership_id => @tom.id, :template_type => 'pillar')
		old_comm.save
		sign_in_as(@admin_agent)
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		within('#terms_of_memberships_table') do
			within("tr", :text => @tom.name) do
				click_link_or_button "Communications"
			end
		end
		click_link_or_button 'New Communication'
		fill_in_form(
			{email_template_name: 'Comm Name', customer_key: 45678}, 
			{"email_template[template_type]" => "Pillar", "email_template[client]" => "Exact Target"}, [])
		click_link_or_button 'Create Email template'
		assert page.has_content?('was successfully created')
	end

	test 'Edit member communications - Logged by General Admin' do
		sign_in_as(@admin_agent)
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		within('#terms_of_memberships_table') do
			within("tr", :text => @tom.name) do
				click_link_or_button "Communications"
			end
		end

		within("#email_templates_table")do
			within("tr", text: @tom.email_templates.first.name)do
			first(:link, "Edit").click
			end
		end
		fill_in_form({email_template_name: 'Edited Comm Name', customer_key: 44444}, {"email_template[client]" => "Exact Target"}, [])
		click_link_or_button 'Update Email template'
		assert page.has_content?('was successfully updated')
	end

	test 'CS send a member communication - Logged by General Acmin' do
		sign_in_as(@admin_agent)
    @club_tom = FactoryGirl.create :terms_of_membership_with_gateway, :club_id => @club.id    
    @club_tom.save
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		within('#terms_of_memberships_table') do
			within("tr", :text => @tom.name) do
				click_link_or_button "Communications"
			end
		end
		@tom.email_templates.where("template_type = 'cancellation'").first.delete
		click_link_or_button 'New Communication'
		fill_in_form(
			{email_template_name: 'Comm Name', customer_key: 45678}, 
			{"email_template[template_type]" => "Cancellation", "email_template[client]" => "Exact Target"}, [])
		click_link_or_button 'Create Email template'
		assert page.has_content?('was successfully created')

		@saved_member = create_active_member(@tom, :active_member)

		assert_difference("Communication.count",1) do
			@saved_member.set_as_canceled!
		end
		communication = @saved_member.communications.find_by_template_type "cancellation"
		assert_not_nil communication
  end
	
	test 'Edit member communications - Logged by Admin_by_club' do
    @agent = FactoryGirl.create(:agent)
    club_role = ClubRole.new :club_id => @club.id
    club_role.agent_id = @agent.id
    club_role.role = "admin"
    club_role.save
		sign_in_as(@agent)
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		within('#terms_of_memberships_table') do
			within("tr", :text => @tom.name) do
				click_link_or_button "Communications"
			end
		end

		within("#email_templates_table")do
			within("tr", text: @tom.email_templates.first.name)do
			first(:link, "Edit").click
			end
		end
		fill_in_form({email_template_name: 'Edited Comm Name', customer_key: 44444}, {"email_template[client]" => "Exact Target"}, [])
		click_link_or_button 'Update Email template'
		assert page.has_content?('was successfully updated')
	end

	test 'Destroy member communications - Logged by Admin_by_club' do
    @agent = FactoryGirl.create(:agent)
    club_role = ClubRole.new :club_id => @club.id
    club_role.agent_id = @agent.id
    club_role.role = "admin"
    club_role.save
		sign_in_as(@agent)
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		within('#terms_of_memberships_table') do
			within("tr", :text => @tom.name) do
				click_link_or_button "Communications"
			end
		end
		assert page.has_content?('Communications')
		first_email_template = @tom.email_templates.first
		within("tr", :text => first_email_template.name) do
			assert_difference("EmailTemplate.count",-1) do
				confirm_ok_js
				click_link_or_button "Destroy"
			end
		end
		assert page.has_content? first_email_template.name
  end

	test 'Destroy member communications - Logged by General Admin' do
		sign_in_as(@admin_agent)
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		within('#terms_of_memberships_table') do
			within("tr", :text => @tom.name) do
				click_link_or_button "Communications"
			end
		end
		assert page.has_content?('Communications')
		first_email_template = @tom.email_templates.first
		within("tr", :text => first_email_template.name) do
			assert_difference("EmailTemplate.count",-1) do
				confirm_ok_js
				click_link_or_button "Destroy"
			end
		end
		assert page.has_content? first_email_template.name
  end

  test "Show all member communications - Logged by Admin_by_club" do
    @club_admin = FactoryGirl.create(:confirmed_admin_agent)
    club_role = ClubRole.new :club_id => @club.id
    club_role.agent_id = @club_admin.id
    club_role.role = "admin"
    club_role.save
    @club_admin.roles = nil
    @club_admin.save
    sign_in_as(@club_admin)
    @tom2 = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id, :name => 'Another Tom')
    communication = FactoryGirl.create(:email_template, :terms_of_membership_id => @tom2.id, :name => "EmailTemplateTest")
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		within('#terms_of_memberships_table') do
			within("tr", :text => @tom.name) do
				click_link_or_button "Communications"				
			end
		end
		assert page.has_content?('Communications')
		@tom.email_templates.each do |email_template|
			assert page.has_content? email_template.name
		end
		assert page.has_no_content? communication.name
  end

	test 'Do not allow enter days_after_join_date = 0 - Logged by Admin_by_club' do
    @club_admin = FactoryGirl.create(:confirmed_admin_agent)
    club_role = ClubRole.new :club_id => @club.id
    club_role.agent_id = @club_admin.id
    club_role.role = "admin"
    club_role.save
    @club_admin.roles = nil
    @club_admin.save
    sign_in_as(@club_admin)
		visit terms_of_memberships_path(@partner.prefix, @club.name)
		within('#terms_of_memberships_table') do
			within("tr", :text => @tom.name) do
				click_link_or_button "Communications"
			end
		end
		click_link_or_button 'New Communication'
		begin
			fill_in_form(
				{email_template_name: 'Comm Name', customer_key: 45678, email_template_days_after_join_date: '0'}, 
				{"email_template[template_type]" => "Pillar", "email_template[client]" => "Exact Target"}, [])
			click_link_or_button 'Create Email template'
		rescue Exception => e
			assert page.has_content?('must be greater than or equal to 1')
		end
  end

	test 'Add member communications - Logged by Admin_by_club' do
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
		fill_in_form(
			{email_template_name: 'Comm Name', customer_key: 45678}, 
			{"email_template[template_type]" => "Pillar", "email_template[client]" => "Exact Target"}, [])
		click_link_or_button 'Create Email template'
		assert page.has_content?('was successfully created')
  end

	test 'Show one member communication - Logged by Admin_by_club' do
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
		communication_name = 'Comm Name'
		within('#terms_of_memberships_table') do
			within("tr", :text => @tom.name) do
				click_link_or_button "Communications"
			end
		end
		click_link_or_button 'New Communication'
		fill_in_form(
			{email_template_name: communication_name, customer_key: 45678}, 
			{"email_template[template_type]" => "Pillar", "email_template[client]" => "Exact Target"}, [])
		click_link_or_button 'Create Email template'
		@et = EmailTemplate.find(:last)
		visit terms_of_membership_email_template_path(@partner.prefix, @club.name, @club_tom.id, @et.id)	
		assert page.has_content?('General Information')
  end

	test 'Do not allow enter member communication duplicate - Logged by Admin_by_club' do
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
		@tom.email_templates.collect(&:template_type).each do |template|
			if template != 'pillar'
				assert page.has_no_xpath? "//select[@id='email_template_template_type']/option[@value = '#{template}']"
			end
		end
	end

	test 'CS send a member communication - Logged by Admin_by_club' do
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
		@tom.email_templates.where("template_type = 'cancellation'").first.delete
		click_link_or_button 'New Communication'
		fill_in_form(
			{email_template_name: 'Comm Name', customer_key: 45678}, 
			{"email_template[template_type]" => "Cancellation", "email_template[client]" => "Exact Target"}, [])
		click_link_or_button 'Create Email template'
		assert page.has_content?('was successfully created')

		@saved_member = create_active_member(@tom, :active_member)

		assert_difference("Communication.count",1) do
			@saved_member.set_as_canceled!
		end
		communication = @saved_member.communications.find_by_template_type "cancellation"
		assert_not_nil communication
  end
end