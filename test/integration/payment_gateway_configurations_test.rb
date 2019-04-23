require 'test_helper'

class PaymentGatewayConfigurationsTest < ActionDispatch::IntegrationTest
  def setup_environment
    @admin_agent  = FactoryBot.create(:confirmed_admin_agent)
    @partner      = FactoryBot.create(:partner)
    @club         = FactoryBot.create(:club, partner_id: @partner.id)
  end

  def fill_in_payment_gateway_configuration(new_pgc, new = true)
    select(I18n.t("activerecord.gateway.#{new_pgc.gateway}"), from: 'payment_gateway_configuration[gateway]') if new
    fill_in 'payment_gateway_configuration[report_group]', with: new_pgc.report_group if new_pgc.report_group && new_pgc.litle?
    fill_in 'payment_gateway_configuration[merchant_key]', with: new_pgc.merchant_key if new_pgc.merchant_key && new_pgc.litle?
    fill_in 'payment_gateway_configuration[login]', with: new_pgc.login if new_pgc.login
    fill_in 'payment_gateway_configuration[password]', with: new_pgc.password if new_pgc.password
    fill_in 'payment_gateway_configuration[descriptor_name]', with: new_pgc.descriptor_name if new_pgc.descriptor_name && new_pgc.litle?
    fill_in 'payment_gateway_configuration[descriptor_phone]', with: new_pgc.descriptor_phone if new_pgc.descriptor_phone && new_pgc.litle?
    fill_in 'payment_gateway_configuration[aus_login]', with: new_pgc.aus_login if new_pgc.aus_login
    fill_in 'payment_gateway_configuration[aus_password]', with: new_pgc.aus_password if new_pgc.aus_password
  end

  test 'Add PGC, Show a PGC and Edit PGC- Login by General Admin' do
    skip('no run now')
    setup_environment
    sign_in_as(@admin_agent)
    visit club_path(@partner.prefix, @club.id)
    click_link_or_button 'New Payment Gateway'
    new_pgc = FactoryBot.build(:payment_gateway_configuration)
    fill_in_payment_gateway_configuration(new_pgc)
    confirm_javascript_ok
    click_link_or_button 'Create Payment gateway configuration'
    assert page.has_content? 'Payment Gateway Configuration created successfully'
    visit club_path(@partner.prefix, @club.id)
    click_link_or_button 'Payment Gateway Configuration'

    wait_until { page.has_content? 'Payment gateway configuration' }
    assert page.has_content? new_pgc.gateway
    assert page.has_content? new_pgc.login

    click_link_or_button 'Edit'
    new_pgc = FactoryBot.build(:payment_gateway_configuration, report_group: 'newReport', merchant_key: 'merchantKey',
                                login: 'newLogin', descriptor_name: 'newDescriptorName', descriptor_phone: 'newDescriptorPhone',
                                aus_login: 'newAusLogin')

    fill_in_payment_gateway_configuration(new_pgc, false)
    confirm_javascript_ok
    click_link_or_button 'Update Payment gateway configuration'

    wait_until { page.has_content? 'Payment Gateway Configuration updated successfully.' }
    assert page.has_content? new_pgc.gateway
    assert page.has_content? 'newLogin'
  end

  test 'Add PGC and Show a PGC - Login by Admin by role' do
    setup_environment
    sign_agent_with_club_role(:agent, :admin)

    visit club_path(@partner.prefix, @club.id)
    click_link_or_button 'New Payment Gateway'
    new_pgc = FactoryBot.build(:payment_gateway_configuration)
    fill_in_payment_gateway_configuration(new_pgc)
    confirm_javascript_ok
    click_link_or_button 'Create Payment gateway configuration'
    assert page.has_content? 'Payment Gateway Configuration created successfully'

    visit club_path(@partner.prefix, @club.id)
    click_link_or_button 'Payment Gateway Configuration'

    wait_until { page.has_content? 'Payment gateway configuration' }
    assert page.has_content? new_pgc.gateway
    assert page.has_content? new_pgc.merchant_key
    assert page.has_content? new_pgc.login
  end

  test 'Do not allow enter PGC duplicated - Login by General Admin' do
    skip('no run now')
    setup_environment
    sign_in_as(@admin_agent)
    @club = FactoryBot.create(:simple_club_with_gateway, partner_id: @partner.id)
    visit club_path(@partner.prefix, @club.id)
    click_link_or_button 'Payment Gateway Configuration'
    FactoryBot.build(:payeezy_payment_gateway_configuration)
    click_link_or_button 'Replace Payment Gateway'
    assert page.has_xpath? '//select[@id="payment_gateway_configuration_gateway"]/option[@value="mes"]'
    assert page.has_xpath? '//select[@id="payment_gateway_configuration_gateway"]/option[@value="authorize_net"]'
    assert page.has_xpath? '//select[@id="payment_gateway_configuration_gateway"]/option[@value="litle"]'
    assert page.has_xpath? '//select[@id="payment_gateway_configuration_gateway"]/option[@value="first_data"]'
    assert page.has_xpath? '//select[@id="payment_gateway_configuration_gateway"]/option[@value="trust_commerce"]'
    assert page.has_xpath? '//select[@id="payment_gateway_configuration_gateway"]/option[@value="stripe"]'
    assert page.has_no_xpath? '//select[@id="payment_gateway_configuration_gateway"]/option[@value="payeezy"]'
  end

  test 'Do not allow to edit a PGC if it has users - Login by General Admin' do
    skip('no run now')
    setup_environment
    sign_in_as(@admin_agent)
    @club = FactoryBot.create(:simple_club_with_gateway, partner_id: @partner.id)
    @user = FactoryBot.create(:user, club_id: @club.id)
    visit club_path(@partner.prefix, @club.id)

    click_link_or_button 'Payment Gateway Configuration'
    wait_until { page.has_content? 'Payment gateway configuration' }
    assert page.has_no_selector? '#new_payment_gateway'
  end
end
