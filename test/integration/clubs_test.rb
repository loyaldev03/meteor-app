require 'test_helper'

class ClubsTest < ActionDispatch::IntegrationTest
  def setup_environment
    @partner = FactoryBot.create(:partner)
    @admin_agent = FactoryBot.create(:confirmed_admin_agent)
    sign_in_as(@admin_agent)
  end

  def configure_checkout_pages(club)
    within('.nav-tabs') do
      click_on('Checkout Pages')
    end
    fill_in 'club[privacy_policy_url]', with: 'http://products.onmc.com/privacy-policy/'
    fill_in 'club[css_style]', with: '.panel-info > .panel-heading {
                                      background-color: #004101 !important;                                      border-color: #004101 !important;
                                      }'
    fill_in 'club[checkout_page_bonus_gift_box_content]', with: club.checkout_page_bonus_gift_box_content
    fill_in 'club[checkout_page_footer]', with: club.checkout_page_footer
    fill_in 'club[thank_you_page_content]', with: club.thank_you_page_content
    fill_in 'club[duplicated_page_content]', with: club.duplicated_page_content
    fill_in 'club[error_page_content]', with: club.error_page_content
    fill_in 'club[result_page_footer]', with: club.result_page_footer
  end

  def configure_mailchimp_mandrill(mailchimp_api_key, mandrill_api_key, mailchimp_list_id)
    within('.nav-tabs') do
      click_on('Marketing Tool')
    end
    select 'Mailchimp/Mandrill', from: 'club[marketing_tool_client]'
    fill_in 'marketing_tool_attributes[mandrill_api_key]', with: mandrill_api_key
    fill_in 'marketing_tool_attributes[mailchimp_api_key]', with: mailchimp_api_key
    fill_in 'marketing_tool_attributes[mailchimp_list_id]', with: mailchimp_list_id
  end

  def fill_in_club(club)
    within('.nav-tabs') do
      click_on('Home')
    end
    fill_in 'club[name]', with: club.name
    fill_in 'club[description]', with: club.description
    fill_in 'club[cs_email]', with: club.cs_email
    fill_in 'club[cs_phone_number]', with: club.cs_phone_number
    attach_file('club[logo]', "#{Rails.root}/test/integration/test_img.png")
    check('club[requires_external_id]')
    select('application', from: 'club[theme]')
    check('club[family_memberships_allowed]')
  end

  test 'creates a club' do
    skip('no run now')
    setup_environment
    unsaved_club = FactoryBot.build(:simple_club_with_gateway)
    visit clubs_path(@partner.prefix)
    click_link_or_button 'New Club'
    fill_in_club(unsaved_club)
    click_link_or_button 'Create Club'
    assert page.has_content?("The club #{unsaved_club.name} was successfully created")
  end

  test 'Search and see clubs' do
    skip('no run now')
    setup_environment
    saved_club = FactoryBot.create(:simple_club_with_gateway, partner_id: @partner.id)
    visit my_clubs_path
    within('#my_clubs_table_filter') do
      find(:css, 'input').set(saved_club.name)
    end
    within('#my_clubs_table') do
      assert page.has_content?(saved_club.id.to_s)
      page.has_content?(saved_club.name)
      assert page.has_content?(saved_club.description)
    end
  end

  test 'should update club' do
    skip('no run now')
    setup_environment
    saved_club = FactoryBot.create(:simple_club_with_gateway, partner_id: @partner.id)
    unsaved_club = FactoryBot.build(:simple_club_with_gateway, partner_id: @partner.id)
    visit clubs_path(@partner.prefix)
    within('#clubs_table') do
      click_link_or_button 'Edit'
    end
    fill_in_club(unsaved_club)
    click_link_or_button 'Update'
    saved_club.reload
    assert page.has_content?("The club #{saved_club.name} was successfully updated.")
    assert_equal(saved_club.reload.description, 'My description')
  end

  test 'should delete club' do
    skip('no run now')
    setup_environment
    saved_club = FactoryBot.create(:simple_club_with_gateway, partner_id: @partner.id)
    visit clubs_path(@partner.prefix)
    within('#clubs_table') do
      click_link_or_button 'Destroy'
      confirm_ok_js
    end
    assert page.has_content?("Club #{saved_club.name} was successfully destroyed")
  end

  test 'should see all clubs as admin on my clubs section' do
    setup_environment
    5.times { FactoryBot.create(:simple_club_with_gateway, partner_id: @partner.id) }
    within('.navbar') { click_link_or_button('My Clubs') }
    within('#my_clubs_table') do
      Club.all.each do |club|
        assert page.has_content?(club.name)
        assert page.has_content?(club.id.to_s)
      end
      assert page.has_content?('Show')
      assert page.has_content?('Edit')
      assert page.has_content?('Users')
      assert page.has_content?('Products')
      assert page.has_content?('Fulfillments')
      assert page.has_content?('Fulfillment Files')
      assert page.has_content?('Suspected Fulfillments')
      assert page.has_content?('Disposition Types')
      assert page.has_content?('Campaigns')
      assert page.has_content?('Campaign Days')
    end
  end

  test 'Configure and Update Mailchimp/Mandrill marketing gateway - Login by General Admin' do
    setup_environment
    skip('no run now')
    unsaved_club = FactoryBot.build(:simple_club_with_gateway)
    visit clubs_path(@partner.prefix)
    click_link_or_button 'New Club'
    fill_in_club(unsaved_club)

    configure_mailchimp_mandrill('mailchimp_api_key_test', 'mandrill_api_key_test', 'list_id_test')

    assert_difference('Club.count', 1) do
      click_link_or_button 'Create Club'
      assert page.has_content?("The club #{unsaved_club.name} was successfully created")
    end
    assert page.has_content? 'mailchimp_api_key_test'
    assert page.has_content? 'mandrill_api_key_test'
    assert page.has_content? 'list_id_test'

    club = Club.last
    assert club.mailchimp_mandrill_client?
    click_link_or_button('Edit')

    configure_mailchimp_mandrill('mailchimp_api_key_test_new', 'mandrill_api_key_test_new', 'list_id_test_new')
    click_link_or_button 'Update Club'
    assert page.has_content? "The club #{club.name} was successfully updated."
  end

  test 'Configure and Update Mailchimp/Mandrill marketing gateway - Login by Admin by Club' do
    setup_environment
    unsaved_club = FactoryBot.build(:simple_club_with_gateway)
    visit clubs_path(@partner.prefix)
    click_link_or_button 'New Club'
    fill_in_club(unsaved_club)

    configure_mailchimp_mandrill('mailchimp_api_key_test', 'mandrill_api_key_test', 'list_id_test')

    assert_difference('Club.count', 1) do
      click_link_or_button 'Create Club'
      assert page.has_content?("The club #{unsaved_club.name} was successfully created")
    end
    assert page.has_content? 'mailchimp_api_key_test'
    assert page.has_content? 'mandrill_api_key_test'
    assert page.has_content? 'list_id_test'

    club = Club.last
    assert club.mailchimp_mandrill_client?
    @admin_agent.update_attribute :roles, ''
    club_role = ClubRole.new club_id: club.id
    club_role.agent_id = @admin_agent.id
    club_role.role = 'admin'
    club_role.save

    click_link_or_button('Edit')
    configure_mailchimp_mandrill('mailchimp_api_key_test_new', 'mandrill_api_key_test_new', 'list_id_test_new')
    click_link_or_button 'Update Club'
    assert page.has_content? "The club #{club.name} was successfully updated."
  end

  test 'Configure and Update Checkout Pages' do
    setup_environment
    unsaved_club = FactoryBot.build(:simple_club_with_gateway)
    visit clubs_path(@partner.prefix)
    click_link_or_button 'New Club'
    fill_in_club(unsaved_club)

    configure_checkout_pages(unsaved_club)

    assert_difference('Club.count', 1) do
      click_link_or_button 'Create Club'
      assert page.has_content?("The club #{unsaved_club.name} was successfully created")
    end
    assert page.has_content? 'http://products.onmc.com/privacy-policy/'
    assert page.has_content? unsaved_club.checkout_page_bonus_gift_box_content
    assert page.has_content? unsaved_club.checkout_page_footer
    assert page.has_content? unsaved_club.thank_you_page_content
    assert page.has_content? unsaved_club.duplicated_page_content
    assert page.has_content? unsaved_club.error_page_content
    assert page.has_content? unsaved_club.result_page_footer

    click_link_or_button('Edit')
    configure_checkout_pages(unsaved_club)
    click_link_or_button 'Update Club'
    assert page.has_content?("The club #{unsaved_club.name} was successfully updated.")
  end
end
