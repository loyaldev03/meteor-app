require 'test_helper'

class TermsOfMembershipTests < ActionController::IntegrationTest
	setup do
		@admin_agent = FactoryGirl.create(:confirmed_admin_agent)
		@partner = FactoryGirl.create(:partner)
		@club = FactoryGirl.create(:club, :partner_id => @partner.id)
		sign_in_as(@admin_agent)
	end

	test "Add PGC, Show a PGC and Edit PGC- Login by General Admin" do
    visit club_path(@partner.prefix, @club.id)
    click_link_or_button "New Payment Gateway"
		new_pgc = FactoryGirl.build(:payment_gateway_configuration)

		select(I18n.t("activerecord.gateway.#{new_pgc.gateway}"), :from => 'payment_gateway_configuration[gateway]')
    fill_in "payment_gateway_configuration[report_group]", with: new_pgc.report_group
    fill_in "payment_gateway_configuration[merchant_key]", with: new_pgc.merchant_key
    fill_in "payment_gateway_configuration[login]", with: new_pgc.login
    fill_in "payment_gateway_configuration[password]", with: new_pgc.password
    fill_in "payment_gateway_configuration[descriptor_name]", with: new_pgc.descriptor_name
    fill_in "payment_gateway_configuration[descriptor_phone]", with: new_pgc.descriptor_phone
    fill_in "payment_gateway_configuration[order_mark]", with: new_pgc.order_mark
    fill_in "payment_gateway_configuration[aus_login]", with: new_pgc.aus_login
    fill_in "payment_gateway_configuration[aus_password]", with: new_pgc.aus_password

    confirm_ok_js
    click_link_or_button "Create Payment gateway configuration"
    assert page.has_content? "Payment Gateway Configuration created successfully"
    
    visit club_path(@partner.prefix, @club.id)
    click_link_or_button "Payment Gateway Configuration"

    wait_until{ page.has_content? "Payment gateway configuration" }
    assert page.has_content? new_pgc.gateway
    assert page.has_content? new_pgc.report_group
    assert page.has_content? new_pgc.merchant_key
    assert page.has_content? new_pgc.login

    click_link_or_button "Edit"
    fill_in "payment_gateway_configuration[report_group]", with: "newReport"
    fill_in "payment_gateway_configuration[merchant_key]", with: "merchantKey"
    fill_in "payment_gateway_configuration[login]", with: "newLogin"
    fill_in "payment_gateway_configuration[descriptor_name]", with: "newDescriptorName"
    fill_in "payment_gateway_configuration[descriptor_phone]", with: "newDescriptorPhone"
    fill_in "payment_gateway_configuration[order_mark]", with: "newOrderMark"
    fill_in "payment_gateway_configuration[aus_login]", with: "newAusLogin"

    click_link_or_button "Update Payment gateway configuration"
    wait_until{ page.has_content? "Payment gateway configuration" }
    assert page.has_content? "newReport"
    assert page.has_content? "merchantKey"
    assert page.has_content? "newLogin"
    assert page.has_content? "newDescriptorPhone"
    assert page.has_content? "newDescriptorName"
    assert page.has_content? "newOrderMark"
    assert page.has_content? "newAusLogin"
	end

  test "Add PGC and Show a PGC - Login by Admin by role" do
    @admin_agent.update_attribute :roles, nil
    club_role = ClubRole.new :club_id => @club.id
    club_role.agent_id = @admin_agent.id
    club_role.role = "admin"
    club_role.save

    visit club_path(@partner.prefix, @club.id)
    click_link_or_button "New Payment Gateway"
    new_pgc = FactoryGirl.build(:payment_gateway_configuration)

    select(I18n.t("activerecord.gateway.#{new_pgc.gateway}"), :from => 'payment_gateway_configuration[gateway]')
    fill_in "payment_gateway_configuration[report_group]", with: new_pgc.report_group
    fill_in "payment_gateway_configuration[merchant_key]", with: new_pgc.merchant_key
    fill_in "payment_gateway_configuration[login]", with: new_pgc.login
    fill_in "payment_gateway_configuration[password]", with: new_pgc.password
    fill_in "payment_gateway_configuration[descriptor_name]", with: new_pgc.descriptor_name
    fill_in "payment_gateway_configuration[descriptor_phone]", with: new_pgc.descriptor_phone
    fill_in "payment_gateway_configuration[order_mark]", with: new_pgc.order_mark
    fill_in "payment_gateway_configuration[aus_login]", with: new_pgc.aus_login
    fill_in "payment_gateway_configuration[aus_password]", with: new_pgc.aus_password

    confirm_ok_js
    click_link_or_button "Create Payment gateway configuration"
    assert page.has_content? "Payment Gateway Configuration created successfully"
    
    visit club_path(@partner.prefix, @club.id)
    click_link_or_button "Payment Gateway Configuration"

    wait_until{ page.has_content? "Payment gateway configuration" }
    assert page.has_content? new_pgc.gateway
    assert page.has_content? new_pgc.report_group
    assert page.has_content? new_pgc.merchant_key
    assert page.has_content? new_pgc.login
  end


	test "Do not allow enter PGC duplicated - Login by General Admin" do
		@club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id)
    visit club_path(@partner.prefix, @club.id)
    click_link_or_button "Payment Gateway Configuration"
		new_pgc = FactoryGirl.build(:payment_gateway_configuration)
    click_link_or_button "New Payment Gateway"

		select(I18n.t("activerecord.gateway.#{new_pgc.gateway}"), :from => 'payment_gateway_configuration[gateway]')
    fill_in "payment_gateway_configuration[report_group]", with: new_pgc.report_group
    fill_in "payment_gateway_configuration[merchant_key]", with: new_pgc.merchant_key
    fill_in "payment_gateway_configuration[login]", with: new_pgc.login
    fill_in "payment_gateway_configuration[password]", with: new_pgc.password
    fill_in "payment_gateway_configuration[descriptor_name]", with: new_pgc.descriptor_name
    fill_in "payment_gateway_configuration[descriptor_phone]", with: new_pgc.descriptor_phone
    fill_in "payment_gateway_configuration[order_mark]", with: new_pgc.order_mark
    fill_in "payment_gateway_configuration[aus_login]", with: new_pgc.aus_login
    fill_in "payment_gateway_configuration[aus_password]", with: new_pgc.aus_password

    confirm_ok_js
    click_link_or_button "Create Payment gateway configuration"
    assert page.has_content? "Gateway already created. There is a payment gateway already configured for this gateway"
	end

	test "Do not allow to edit a PGC if it has members - Login by General Admin" do
		@club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id)
    @member = FactoryGirl.create(:member, :club_id => @club.id)
    visit club_path(@partner.prefix, @club.id)

    click_link_or_button "Payment Gateway Configuration"
    wait_until{ page.has_content? "Payment gateway configuration" }
    assert page.has_no_selector? "#new_payment_gateway"
	end
end