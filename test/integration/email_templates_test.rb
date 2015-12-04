
require 'test_helper'

class EmailTemplatesTest < ActionDispatch::IntegrationTest
  setup do
    @admin_agent = FactoryGirl.create(:confirmed_admin_agent)
    @partner = FactoryGirl.create(:partner)
    @club = FactoryGirl.create(:simple_club_with_gateway, partner_id: @partner.id, :marketing_tool_client => "action_mailer")
    @tom = FactoryGirl.create(:terms_of_membership_with_gateway, club_id: @club.id, name: 'TOM for Email Templates Test')
    @communication = FactoryGirl.create(:email_template_for_action_mailer, terms_of_membership_id: @tom.id)
  end

  def fill_in_form(options_for_texts = {}, options_for_selects = {}, options_for_checkboxs = [])
    options_for_checkboxs.each do |value|
      choose(value)
    end
    options_for_selects.each do |field, value|
      select(value, from: field)
    end
    options_for_texts.each do |field, value|
      fill_in field, with: value
    end
  end

  def create_email_template_and_send_communication(opt_for_texts = {}, opt_for_selects = {}, options_for_checkboxs = [])
    visit terms_of_memberships_path(@partner.prefix, @club.name)
    within('#terms_of_memberships_table') do
      within("tr", text: @tom.name) do
        click_link_or_button "Communications"
      end
    end
    @tom.email_templates.where("template_type = 'cancellation'").first.delete
    click_link_or_button 'New Communication'
    fill_in_form(opt_for_texts, opt_for_selects, [])
    click_link_or_button 'Create Email template'
    assert page.has_content?('was successfully created')

    @saved_user = create_active_user(@tom, :active_user)

    assert_difference("Communication.count",1) do
      @saved_user.set_as_canceled!
    end
    communication = @saved_user.communications.find_by template_type: "cancellation"
    assert_not_nil communication
    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)
    within(".nav-tabs"){ click_on("Communications") }
    within("#communications") do
      assert page.has_content? communication.template_name
    end
  end

  test 'Show all user communications - Logged by General Admin' do
    sign_in_as(@admin_agent)
    visit terms_of_memberships_path(@partner.prefix, @club.name)
    @tom2 = FactoryGirl.create(:terms_of_membership_with_gateway, club_id: @club.id, name: 'TOM for Email Templates Test2')
    communication = FactoryGirl.create(:email_template, terms_of_membership_id: @tom2.id, name: "EmailTemplateTest")
    within('#terms_of_memberships_table') do
      within("tr", text: @tom.name) do
        click_link_or_button "Communications"
      end
    end
    assert page.has_content?('Communications')
    @tom.email_templates.each do |email_template|
      assert page.has_content? email_template.name
    end
    assert page.has_no_content? communication.name
  end

  test 'Add user communications - Logged by General Admin' do
    sign_in_as(@admin_agent)
    visit terms_of_memberships_path(@partner.prefix, @club.name)
    within('#terms_of_memberships_table') do
      within("tr", text: @tom.name) do
        click_link_or_button "Communications"
      end
    end
    click_link_or_button 'New Communication'
    fill_in_form(
      {email_template_name: 'Comm Name'}, 
      {"email_template[template_type]" => "Pillar"}, [])
    click_link_or_button 'Create Email template'

    assert page.has_content?('was successfully created')
  end

  test 'Do not allow enter days = 0 - Logged by General Admin' do
    sign_in_as(@admin_agent)
    visit terms_of_memberships_path(@partner.prefix, @club.name)
    within('#terms_of_memberships_table') do
      within("tr", text: @tom.name) do
        click_link_or_button "Communications"
      end
    end
    click_link_or_button 'New Communication'
    begin
      fill_in_form(
        {email_template_name: 'Comm Name', email_template_days: '0'}, 
        {"email_template[template_type]" => "Pillar"}, [])
      click_link_or_button 'Create Email template'
    rescue Exception => e
      assert page.has_content?('must be greater than or equal to 1')
    end
  end

  test 'Show one user communication - Logged by General Admin' do
    communication_name = 'Comm Name'
    sign_in_as(@admin_agent)
    visit terms_of_memberships_path(@partner.prefix, @club.name)
    within('#terms_of_memberships_table') do
      within("tr", text: @tom.name) do
        click_link_or_button "Communications"
      end
    end
    click_link_or_button 'New Communication'
    fill_in_form(
      {email_template_name: communication_name}, 
      {"email_template[template_type]" => "Pillar"}, [])
    click_link_or_button 'Create Email template'
    @et = EmailTemplate.last
    visit terms_of_membership_email_template_path(@partner.prefix, @club.name, @tom.id, @et.id) 
    assert page.has_content?('General Information')
  end

  test 'Allow to create more than one user communication with Pillar type - Logged by General Admin' do
    old_comm = FactoryGirl.create(:email_template, terms_of_membership_id: @tom.id, template_type: 'pillar')
    old_comm.save
    sign_in_as(@admin_agent)
    visit terms_of_memberships_path(@partner.prefix, @club.name)
    within('#terms_of_memberships_table') do
      within("tr", text: @tom.name) do
        click_link_or_button "Communications"
      end
    end
    click_link_or_button 'New Communication'
    fill_in_form(
      {email_template_name: 'Comm Name'}, 
      {"email_template[template_type]" => "Pillar"}, [])
    click_link_or_button 'Create Email template'
    assert page.has_content?('was successfully created')
  end

  test 'Edit user communications - Logged by General Admin' do
    sign_in_as(@admin_agent)
    visit terms_of_memberships_path(@partner.prefix, @club.name)
    within('#terms_of_memberships_table') do
      within("tr", text: @tom.name) do
        click_link_or_button "Communications"
      end
    end

    within("#email_templates_table")do
      within("tr", text: @tom.email_templates.first.name)do
      first(:link, "Edit").click
      end
    end
    fill_in_form({email_template_name: 'Edited Comm Name'}, {}, [])
    click_link_or_button 'Update Email template'
    assert page.has_content?('was successfully updated')
  end

  test 'CS send an user communication - Logged by General Admin' do
    sign_in_as(@admin_agent)
    @club_tom = FactoryGirl.create :terms_of_membership_with_gateway, club_id: @club.id
    @club_tom.save
    #action_mailer
    create_email_template_and_send_communication({email_template_name: 'Comm Name New'}, {"email_template[template_type]" => "Cancellation"}, [])
    #exat_target
    @club.update_attributes marketing_tool_client: "exact_target", marketing_tool_attributes: { "et_business_unit" => "12345", "et_prospect_list" => "1235", "et_members_list" => "12345", "et_username" => "12345", "et_password" => "12345" }
    create_email_template_and_send_communication({email_template_name: 'Comm Name New', customer_key: 12345}, {"email_template[template_type]" => "Cancellation"}, [])
    #mandrill
    @club.update_attributes marketing_tool_client: "mailchimp_mandrill", marketing_tool_attributes: { "mailchimp_api_key" => "12345", "mailchimp_list_id" => "1235", "mandrill_api_key" => "12345" }
    create_email_template_and_send_communication({email_template_name: 'Comm Name New', template_name: "cancellation2"}, {"email_template[template_type]" => "Cancellation"}, [])
  end
  
  test "Show and create users comms only for marketing client configured - Login by General Admin" do
    @club.update_attributes marketing_tool_client: 'exact_target'
    sign_in_as(@admin_agent)
    visit terms_of_memberships_path(@partner.prefix, @club.name)
    within('#terms_of_memberships_table') do
      within("tr", text: @tom.name) do
        click_link_or_button "Communications"
      end
    end
    click_link_or_button 'New Communication'
    fill_in_form(
      {email_template_name: 'Comm Name New', customer_key: 12345}, 
      {"email_template[template_type]" => "Pillar"}, [])
    click_link_or_button 'Create Email template'

    assert page.has_content?('was successfully created')
    @tom.email_templates.where(client: 'action_mailer').each do |email_template|
      assert page.has_no_content? email_template.name
    end
    email_template = EmailTemplate.last
    assert page.has_content? email_template.name
    assert_equal @club.marketing_tool_client, email_template.client

    @club.update_attributes marketing_tool_client: 'mailchimp_mandrill'
    visit terms_of_memberships_path(@partner.prefix, @club.name)
    within('#terms_of_memberships_table') do
      within("tr", text: @tom.name) do
        click_link_or_button "Communications"
      end
    end
    click_link_or_button 'New Communication'
    fill_in_form(
      {email_template_name: 'Mailchimp Comm', template_name: "TemplateName"}, 
      {"email_template[template_type]" => "Pillar"}, [])
    click_link_or_button 'Create Email template'

    assert page.has_content?('was successfully created')
    @tom.email_templates.where("client in ('action_mailer','exact_target')").each do |email_template|
      assert page.has_no_content? email_template.name
    end
    email_template = EmailTemplate.last
    assert page.has_content? email_template.name
    assert_equal @club.marketing_tool_client, email_template.client
  end

  test 'Edit user communications - Logged by Admin_by_club' do
    @agent = FactoryGirl.create(:agent)
    club_role = ClubRole.new club_id: @club.id
    club_role.agent_id = @agent.id
    club_role.role = "admin"
    club_role.save
    sign_in_as(@agent)
    visit terms_of_memberships_path(@partner.prefix, @club.name)
    within('#terms_of_memberships_table') do
      within("tr", text: @tom.name) do
        click_link_or_button "Communications"
      end
    end

    within("#email_templates_table")do
      within("tr", text: @tom.email_templates.first.name)do
      first(:link, "Edit").click
      end
    end
    fill_in_form({email_template_name: 'Edited Comm Name'}, {}, [])
    click_link_or_button 'Update Email template'
    assert page.has_content?('was successfully updated')
  end

  test 'Destroy user communications - Logged by Admin_by_club' do
    @agent = FactoryGirl.create(:agent)
    club_role = ClubRole.new club_id: @club.id
    club_role.agent_id = @agent.id
    club_role.role = "admin"
    club_role.save
    sign_in_as(@agent)
    visit terms_of_memberships_path(@partner.prefix, @club.name)
    within('#terms_of_memberships_table') do
      within("tr", text: @tom.name) do
        click_link_or_button "Communications"
      end
    end
    assert page.has_content?('Communications')
    first_email_template = @tom.email_templates.first
    within("tr", text: first_email_template.name) do
      assert_difference("EmailTemplate.count",-1) do
        confirm_ok_js
        click_link_or_button "Destroy"
      end
    end
    assert page.has_content? first_email_template.name
  end

  test 'Destroy user communications - Logged by General Admin' do
    sign_in_as(@admin_agent)
    visit terms_of_memberships_path(@partner.prefix, @club.name)
    within('#terms_of_memberships_table') do
      within("tr", text: @tom.name) do
        click_link_or_button "Communications"
      end
    end
    assert page.has_content?('Communications')
    first_email_template = @tom.email_templates.first
    within("tr", text: first_email_template.name) do
      assert_difference("EmailTemplate.count",-1) do
        confirm_ok_js
        click_link_or_button "Destroy"
      end
    end
    assert page.has_content? first_email_template.name
  end

  test "Show all user communications - Logged by Admin_by_club" do
    @club_admin = FactoryGirl.create(:confirmed_admin_agent)
    club_role = ClubRole.new club_id: @club.id
    club_role.agent_id = @club_admin.id
    club_role.role = "admin"
    club_role.save
    @club_admin.roles = nil
    @club_admin.save
    sign_in_as(@club_admin)
    @tom2 = FactoryGirl.create(:terms_of_membership_with_gateway, club_id: @club.id, name: 'Another Tom')
    communication = FactoryGirl.create(:email_template, terms_of_membership_id: @tom2.id, name: "EmailTemplateTest")
    visit terms_of_memberships_path(@partner.prefix, @club.name)
    within('#terms_of_memberships_table') do
      within("tr", text: @tom.name) do
        click_link_or_button "Communications"       
      end
    end
    assert page.has_content?('Communications')
    @tom.email_templates.each do |email_template|
      assert page.has_content? email_template.name
    end
    assert page.has_no_content? communication.name
  end

  test 'Do not allow enter days = 0 - Logged by Admin_by_club' do
    @club_admin = FactoryGirl.create(:confirmed_admin_agent)
    club_role = ClubRole.new club_id: @club.id
    club_role.agent_id = @club_admin.id
    club_role.role = "admin"
    club_role.save
    @club_admin.roles = nil
    @club_admin.save
    sign_in_as(@club_admin)
    visit terms_of_memberships_path(@partner.prefix, @club.name)
    within('#terms_of_memberships_table') do
      within("tr", text: @tom.name) do
        click_link_or_button "Communications"
      end
    end
    click_link_or_button 'New Communication'
    begin
      fill_in_form(
        {email_template_name: 'Comm Name', email_template_days: '0'}, 
        {"email_template[template_type]" => "Pillar"}, [])
      click_link_or_button 'Create Email template'
    rescue Exception => e
      assert page.has_content?('must be greater than or equal to 1')
    end
  end

  test 'Add user communications - Logged by Admin_by_club' do
    @club_admin = FactoryGirl.create(:confirmed_admin_agent)
    club_role = ClubRole.new club_id: @club.id
    club_role.agent_id = @club_admin.id
    club_role.role = "admin"
    club_role.save
    @club_admin.roles = nil
    @club_admin.save
    sign_in_as(@club_admin)
    @club_tom = FactoryGirl.create :terms_of_membership_with_gateway, club_id: @club.id    
    @club_tom.save
    visit terms_of_memberships_path(@partner.prefix, @club.name)
    within('#terms_of_memberships_table') do
      within("tr", text: @tom.name) do
        click_link_or_button "Communications"
      end
    end
    click_link_or_button 'New Communication'
    fill_in_form(
      {email_template_name: 'Comm Name'}, 
      {"email_template[template_type]" => "Pillar"}, [])
    click_link_or_button 'Create Email template'
    assert page.has_content?('was successfully created')
  end

  test 'Show one user communication - Logged by Admin_by_club' do
    @club_admin = FactoryGirl.create(:confirmed_admin_agent)
    club_role = ClubRole.new club_id: @club.id
    club_role.agent_id = @club_admin.id
    club_role.role = "admin"
    club_role.save
    @club_admin.roles = nil
    @club_admin.save
    sign_in_as(@club_admin)
    @club_tom = FactoryGirl.create :terms_of_membership_with_gateway, club_id: @club.id    
    @club_tom.save
    visit terms_of_memberships_path(@partner.prefix, @club.name)  
    communication_name = 'Comm Name'
    within('#terms_of_memberships_table') do
      within("tr", text: @tom.name) do
        click_link_or_button "Communications"
      end
    end
    click_link_or_button 'New Communication'
    fill_in_form(
      {email_template_name: communication_name}, 
      {"email_template[template_type]" => "Pillar"}, [])
    click_link_or_button 'Create Email template'
    @et = EmailTemplate.last
    visit terms_of_membership_email_template_path(@partner.prefix, @club.name, @club_tom.id, @et.id)  
    assert page.has_content?('General Information')
  end

  test 'Do not allow enter user communication duplicate - Logged by Admin_by_club' do
    @club_admin = FactoryGirl.create(:confirmed_admin_agent)
    club_role = ClubRole.new club_id: @club.id
    club_role.agent_id = @club_admin.id
    club_role.role = "admin"
    club_role.save
    @club_admin.roles = nil
    @club_admin.save
    sign_in_as(@club_admin)
    @club_tom = FactoryGirl.create :terms_of_membership_with_gateway, club_id: @club.id    
    @club_tom.save
    visit terms_of_memberships_path(@partner.prefix, @club.name)
    within('#terms_of_memberships_table') do
      within("tr", text: @tom.name) do
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

  test 'CS send an user communication - Logged by Admin_by_club' do
    @club_admin = FactoryGirl.create(:confirmed_admin_agent)
    club_role = ClubRole.new club_id: @club.id
    club_role.agent_id = @club_admin.id
    club_role.role = "admin"
    club_role.save
    @club_admin.roles = nil
    @club_admin.save
    sign_in_as(@club_admin)
    @club_tom = FactoryGirl.create :terms_of_membership_with_gateway, :club_id => @club.id    
    @club_tom.save
    #action_mailer
    create_email_template_and_send_communication({email_template_name: 'Comm Name New'}, {"email_template[template_type]" => "Cancellation"}, [])
    #exat_target
    @club.update_attributes marketing_tool_client: "exact_target", marketing_tool_attributes: { "et_business_unit" => "12345", "et_prospect_list" => "1235", "et_members_list" => "12345", "et_username" => "12345", "et_password" => "12345" }
    create_email_template_and_send_communication({email_template_name: 'Comm Name New', customer_key: 12345}, {"email_template[template_type]" => "Cancellation"}, [])
    #mandrill
    @club.update_attributes marketing_tool_client: "mailchimp_mandrill", marketing_tool_attributes: { "mailchimp_api_key" => "12345", "mailchimp_list_id" => "1235", "mandrill_api_key" => "12345" }
    create_email_template_and_send_communication({email_template_name: 'Comm Name New', template_name: "cancellation2"}, {"email_template[template_type]" => "Cancellation"}, [])
  end

  test "Show and create users comms only for marketing client configured - Login by Admin_by_club" do
    @club.update_attributes :marketing_tool_client => 'exact_target'
    @club_admin = FactoryGirl.create(:confirmed_admin_agent)
    club_role = ClubRole.new club_id: @club.id
    club_role.agent_id = @club_admin.id
    club_role.role = "admin"
    club_role.save
    @club_admin.roles = nil
    @club_admin.save
    sign_in_as(@club_admin)
    visit terms_of_memberships_path(@partner.prefix, @club.name)
    within('#terms_of_memberships_table') do
      within("tr", text: @tom.name) do
        click_link_or_button "Communications"
      end
    end
    click_link_or_button 'New Communication'
    fill_in_form(
      {email_template_name: 'Comm Name New', customer_key: 12345}, 
      {"email_template[template_type]" => "Pillar"}, [])
    click_link_or_button 'Create Email template'

    assert page.has_content?('was successfully created')
    @tom.email_templates.where(client: 'action_mailer').each do |email_template|
      assert page.has_no_content? email_template.name
    end
    email_template = EmailTemplate.last
    assert page.has_content? email_template.name
    assert_equal @club.marketing_tool_client, email_template.client

    @club.update_attributes marketing_tool_client: 'mailchimp_mandrill'
    visit terms_of_memberships_path(@partner.prefix, @club.name)
    within('#terms_of_memberships_table') do
      within("tr", text: @tom.name) do
        click_link_or_button "Communications"
      end
    end
    click_link_or_button 'New Communication'
    fill_in_form(
      {email_template_name: 'Mailchimp Comm', template_name: "TemplateName"}, 
      {"email_template[template_type]" => "Pillar"}, [])
    click_link_or_button 'Create Email template'

    assert page.has_content?('was successfully created')
    @tom.email_templates.where("client in ('action_mailer','exact_target')").each do |email_template|
      assert page.has_no_content? email_template.name
    end
    email_template = EmailTemplate.last
    assert page.has_content? email_template.name
    assert_equal @club.marketing_tool_client, email_template.client
  end

  ############################################################
  ## COMMUNICATION TEST
  ############################################################

  test "Do not send any communication if you do not enter a Member ID" do
    sign_in_as(@admin_agent)
    visit terms_of_membership_test_communications_path partner_prefix: @partner.prefix, club_prefix: @club.name, terms_of_membership_id: @tom.id
    alert_ok_js
    within("#communications_table") do
      first(:link, 'send').click
    end
    assert page.has_no_content? I18n.t('error_messages.testing_communication_send')
  end
end