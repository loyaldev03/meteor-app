require 'test_helper'

class PaymentGatewayConfigurationTest < ActionDispatch::IntegrationTest
  setup do
    @admin_agent = FactoryGirl.create(:confirmed_admin_agent)
    @partner = FactoryGirl.create(:partner)
    @club = FactoryGirl.create(:club, partner_id: @partner.id)
    sign_in_as(@admin_agent)
  end

  def fill_in_payment_gateway_configuration(new_pgc, new=true)
    select(I18n.t("activerecord.gateway.#{new_pgc.gateway}"), from: 'payment_gateway_configuration[gateway]') if new
    fill_in "payment_gateway_configuration[report_group]", with: new_pgc.report_group if new_pgc.report_group and new_pgc.litle?
    fill_in "payment_gateway_configuration[merchant_key]", with: new_pgc.merchant_key if new_pgc.merchant_key and (new_pgc.litle?)
    fill_in "payment_gateway_configuration[login]", with: new_pgc.login if new_pgc.login
    fill_in "payment_gateway_configuration[password]", with: new_pgc.password if new_pgc.password
    fill_in "payment_gateway_configuration[descriptor_name]", with: new_pgc.descriptor_name if new_pgc.descriptor_name and new_pgc.litle?
    fill_in "payment_gateway_configuration[descriptor_phone]", with: new_pgc.descriptor_phone if new_pgc.descriptor_phone and new_pgc.litle?
    fill_in "payment_gateway_configuration[aus_login]", with: new_pgc.aus_login if new_pgc.aus_login
    fill_in "payment_gateway_configuration[aus_password]", with: new_pgc.aus_password if new_pgc.aus_password
    confirm_ok_js
      end

  test "Add PGC, Show a PGC and Edit PGC- Login by General Admin" do
    visit club_path(@partner.prefix, @club.id)
    click_link_or_button "New Payment Gateway"
    new_pgc = FactoryGirl.build(:payment_gateway_configuration)
    
    fill_in_payment_gateway_configuration(new_pgc)
    click_link_or_button "Create Payment gateway configuration"
    assert page.has_content? "Payment Gateway Configuration created successfully"

    visit club_path(@partner.prefix, @club.id)
    click_link_or_button "Payment Gateway Configuration"

    wait_until{ page.has_content? "Payment gateway configuration" }
    assert page.has_content? new_pgc.gateway
    assert page.has_content? new_pgc.login

    click_link_or_button "Edit"
    new_pgc = FactoryGirl.build(:payment_gateway_configuration, report_group: "newReport", merchant_key: "merchantKey",
                                login: "newLogin", descriptor_name: "newDescriptorName", descriptor_phone: "newDescriptorPhone",
                                aus_login: "newAusLogin" )

    fill_in_payment_gateway_configuration(new_pgc, false)
    click_link_or_button "Update Payment gateway configuration"
    wait_until{ page.has_content? "Payment gateway configuration" }
    assert page.has_content? new_pgc.gateway
    assert page.has_content? "newLogin"
  end

  test "Add PGC and Show a PGC - Login by Admin by role" do
    @admin_agent.update_attribute :roles, nil
    club_role = ClubRole.new club_id: @club.id
    club_role.agent_id = @admin_agent.id
    club_role.role = "admin"
    club_role.save

    visit club_path(@partner.prefix, @club.id)
    click_link_or_button "New Payment Gateway"
    new_pgc = FactoryGirl.build(:payment_gateway_configuration)
    fill_in_payment_gateway_configuration(new_pgc)
    confirm_ok_js
    click_link_or_button "Create Payment gateway configuration"
    assert page.has_content? "Payment Gateway Configuration created successfully"
    
    visit club_path(@partner.prefix, @club.id)
    click_link_or_button "Payment Gateway Configuration"

    wait_until{ page.has_content? "Payment gateway configuration" }
    assert page.has_content? new_pgc.gateway
    assert page.has_content? new_pgc.merchant_key
    assert page.has_content? new_pgc.login
  end

  test "Do not allow enter PGC duplicated - Login by General Admin" do
    @club = FactoryGirl.create(:simple_club_with_gateway, partner_id: @partner.id)
    visit club_path(@partner.prefix, @club.id)
    click_link_or_button "Payment Gateway Configuration"
    new_pgc = FactoryGirl.build(:payment_gateway_configuration)
    click_link_or_button "Replace Payment Gateway"
    assert page.has_xpath? '//select[@id="payment_gateway_configuration_gateway"]/option[@value="authorize_net"]'
    assert page.has_xpath? '//select[@id="payment_gateway_configuration_gateway"]/option[@value="litle"]'
    assert page.has_no_xpath? '//select[@id="payment_gateway_configuration_gateway"]/option[@value="mes"]'
  end

  test "Do not allow to edit a PGC if it has users - Login by General Admin" do
    @club = FactoryGirl.create(:simple_club_with_gateway, partner_id: @partner.id)
    @user = FactoryGirl.create(:user, club_id: @club.id)
    visit club_path(@partner.prefix, @club.id)

    click_link_or_button "Payment Gateway Configuration"
    wait_until{ page.has_content? "Payment gateway configuration" }
    assert page.has_no_selector? "#new_payment_gateway"
  end
end