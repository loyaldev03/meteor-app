require 'test_helper'

class UsersFulfillmentTest < ActionDispatch::IntegrationTest
  def setup
    active_merchant_stubs_payeezy
    FactoryBot.create(:batch_agent)
    @admin_agent                      = FactoryBot.create(:confirmed_admin_agent)
    @club                             = FactoryBot.create(:simple_club_with_gateway)
    @terms_of_membership_with_gateway = FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club.id)
    @partner                          = @club.partner
    Time.zone                         = @club.time_zone
    @product                          = Product.find_by sku: Settings.others_product, club_id: @club.id
    sign_in_as(@admin_agent)
  end

  def setup_user
    @saved_user   = create_user_throught_sloop(FactoryBot.build(:membership_with_enrollment_info, product_sku: Settings.others_product))
    @fulfillment  = @saved_user.fulfillments.find_by product_sku: Settings.others_product
  end

  def create_user_throught_sloop(enrollment_info)
    @credit_card  = FactoryBot.build :credit_card
    @user         = FactoryBot.build :user_with_api
    create_user_by_sloop(@admin_agent, @user, @credit_card, enrollment_info, @terms_of_membership_with_gateway)
    @saved_user = User.find_by email: @user.email
  end

  test 'cancel user and check if not_processed fulfillment status were updated to canceled' do
    setup_user
    @fulfillment.set_as_not_processed
    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)
    within('.nav-tabs') { click_on('Fulfillments') }
    within('#fulfillments') { assert page.has_content?('not_processed') }

    @saved_user.set_as_canceled!
    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)
    within('.nav-tabs') { click_on('Fulfillments') }
    within('#fulfillments') { assert page.has_content?('canceled') }
  end

  test 'cancel user and check if in_process fulfillment status were updated to canceled' do
    setup_user
    @fulfillment.set_as_in_process
    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)
    within('.nav-tabs') { click_on('Fulfillments') }
    within('#fulfillments') { assert page.has_content?('in_process') }

    @saved_user.set_as_canceled!
    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)
    within('.nav-tabs') { click_on('Fulfillments') }
    within('#fulfillments') { assert page.has_content?('canceled') }
    assert_equal @fulfillment.reload.status, 'canceled'
  end

  test 'cancel user and check if out_of_stock fulfillments were updated to canceled' do
    setup_user
    @fulfillment.set_as_out_of_stock

    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)
    within('.nav-tabs') { click_on('Fulfillments') }
    within('#fulfillments') { assert page.has_content?('out_of_stock') }

    @saved_user.set_as_canceled!
    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)
    within('.nav-tabs') { click_on('Fulfillments') }
    within('#fulfillments') { assert page.has_content?('canceled') }
    @fulfillment.reload
    assert_equal @fulfillment.status, 'canceled'
  end

  test 'cancel user and check if bad_address fulfillments were updated to canceled' do
    setup_user
    @fulfillment.set_as_in_process
    @fulfillment.set_as_bad_address

    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)
    within('.nav-tabs') { click_on('Fulfillments') }
    within('#fulfillments') { assert page.has_content?('bad_address') }
    @saved_user.set_as_canceled!

    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)
    within('.nav-tabs') { click_on('Fulfillments') }
    within('#fulfillments') { assert page.has_content?('canceled') }
    assert_equal @fulfillment.reload.status, 'canceled'
  end

  test 'cancel user and check if sent fulfillment status were not updated to canceled' do
    setup_user
    @fulfillment.set_as_in_process
    @fulfillment.set_as_sent
    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)
    within('.nav-tabs') { click_on('Fulfillments') }
    within('#fulfillments') { assert page.has_content?('sent') }

    @saved_user.set_as_canceled!
    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)
    within('.nav-tabs') { click_on('Fulfillments') }
    within('#fulfillments') { assert page.has_content?('sent') }
    assert_equal @fulfillment.reload.status, 'sent'
  end

  test 'enroll an user with blank product_sku' do
    enrollment_info = FactoryBot.build(:membership_with_enrollment_info, product_sku: '')
    assert_difference('Fulfillment.count', 0) do
      create_user_throught_sloop(enrollment_info)
    end

    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)
    assert find_field('input_first_name').value == @saved_user.first_name
    within('.nav-tabs') { click_on('Fulfillments') }
    within('#fulfillments') { assert page.has_content?('No fulfillments were found.') }
  end

  test "Set a fulfillment to cancel status from user's profile" do
    @product        = FactoryBot.create(:product_with_recurrent, club_id: @club.id)
    enrollment_info = FactoryBot.build(:membership_with_enrollment_info, product_sku: @product.sku)
    create_user_throught_sloop(enrollment_info)
    fulfillment = Fulfillment.last

    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)
    assert find_field('input_first_name').value == @saved_user.first_name
    within('.nav-tabs') { click_on('Fulfillments') }
    within('#fulfillments') do
      assert page.has_content? I18n.l @saved_user.join_date, format: :only_date
      assert page.has_content? I18n.l fulfillment.renewable_at, format: :only_date
      assert page.has_content? @product.sku
      assert page.has_content? 'not_processed'
      click_link_or_button 'Cancel'
      confirm_ok_js
    end
    wait_until { page.has_content?("Changed status on Fulfillment ##{fulfillment.id} #{@product.sku} from not_processed to canceled") }
  end

  test "Set a fulfillment to do_not_honor status from user's profile" do
    @product        = FactoryBot.create(:product_with_recurrent, club_id: @club.id)
    enrollment_info = FactoryBot.build(:membership_with_enrollment_info, product_sku: @product.sku, enrollment_amount: 0.0)
    create_user_throught_sloop(enrollment_info)

    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)
    within('.nav-tabs') { click_on('Fulfillments') }
    within('#fulfillments') do
      assert page.has_content?('not_processed')
      assert page.has_no_content?('manual_review_required')
      assert page.has_no_selector?('Do not honor')
    end

    unsaved_user  = FactoryBot.build(:active_user, first_name: @saved_user.first_name, last_name: @saved_user.last_name, state: @saved_user.last_name)
    @saved_user   = create_user_by_sloop(@admin_agent, unsaved_user, nil, enrollment_info, @terms_of_membership_with_gateway, true, true)
    fulfillment   = Fulfillment.last
    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)
    assert find_field('input_first_name').value == @saved_user.first_name
    within('.nav-tabs') { click_on('Fulfillments') }
    within('#fulfillments') do
      assert page.has_content? I18n.l @saved_user.join_date, format: :only_date
      assert page.has_content? I18n.l fulfillment.renewable_at, format: :only_date
      assert page.has_content? @product.sku
      assert page.has_no_content?('not_processed')
      assert page.has_content?('manual_review_required')
      click_link_or_button('Do not honor')
      confirm_ok_js
    end
    wait_until { page.has_content?("Changed status on Fulfillment ##{fulfillment.id} #{@product.sku} from manual_review_required to do_not_honor") }
  end

  test 'show cancel or do_not_honor buttons if product is in not_process.' do
    @product        = FactoryBot.create(:product_with_recurrent, club_id: @club.id)
    enrollment_info = FactoryBot.build(:membership_with_enrollment_info, product_sku: @product.sku)
    create_user_throught_sloop(enrollment_info)

    Fulfillment.state_machines[:status].states.map(&:name).each do |status|
      Fulfillment.update_all status: status
      visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)
      assert find_field('input_first_name').value == @saved_user.first_name
      within('.nav-tabs') { click_on('Fulfillments') }
      within('#fulfillments') do
        assert page.has_content?(@product.sku)
        if %w[not_processed manual_review_required].include? status
          assert page.has_selector?('Set as not processed') if status == 'manual_review_required'
          assert page.has_selector? 'Cancel'
          assert page.has_selector? 'Do not honor'
        else
          assert page.has_no_selector? 'Cancel'
          assert page.has_no_selector? 'Do not honor'
        end
      end
    end
  end

  test "Change fulfillment status from bad_address to not_processed after updating address on user's profile" do
    setup_user
    @fulfillment.set_as_in_process
    @saved_user.set_wrong_address(@admin_agent, 'admin')
    @fulfillment.reload
    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)

    within('.nav-tabs') { click_on('Fulfillments') }
    within('#fulfillments') do
      assert page.has_content?(@fulfillment.product_sku)
      assert page.has_content?('bad_address')
    end

    click_link_or_button 'Edit'
    within('#table_demographic_information') do
      fill_in 'user[address]', with: 'NewAddress'
    end
    alert_ok_js
    click_link_or_button 'Update User'
    sleep 2
    assert find_field('input_first_name').value == @saved_user.first_name
    within('.nav-tabs') { click_on('Fulfillments') }
    within('#fulfillments') do
      assert page.has_content?(@fulfillment.product_sku)
      assert page.has_content?('not_processed')
    end
  end

  test 'Agents can not change fulfillment status from User Profile' do
    setup_user
    enrollment_info = FactoryBot.build(:membership_with_enrollment_info)
    create_user_throught_sloop(enrollment_info)
    5.times { FactoryBot.create(:fulfillment, user_id: @saved_user.id, product_sku: @product.sku, product_id: @product.id, club_id: @club.id) }

    visit show_user_path(partner_prefix: @saved_user.club.partner.prefix, club_prefix: @saved_user.club.name, user_prefix: @saved_user.id)
    assert find_field('input_first_name').value == @saved_user.first_name

    within('.nav-tabs') { click_on 'Fulfillments' }
    within('#fulfillments') { assert page.has_no_selector?('#mark_as_sent') }
    within('#fulfillments') { assert page.has_no_selector?('#update_fulfillment_status') }
  end

  test "Change fulfillment status from not_process to bad_address after mark an user as 'wrong address'" do
    setup_user
    3.times { FactoryBot.create(:fulfillment, user_id: @saved_user.id, product_sku: @product.sku, product_id: @product.id, club_id: @club.id) }

    set_as_undeliverable_user(@saved_user, 'reason')

    within('#table_demographic_information') do
      assert page.has_css?('tr.yellow')
    end
    @saved_user.reload.fulfillments do |fulfillment|
      assert_equal fulfillment.status, 'bad_address'
    end
  end

  test "Change fulfillment status from in_process to bad_address after mark an user as 'wrong address'" do
    setup_user
    3.times { FactoryBot.create(:fulfillment, user_id: @saved_user.id, product_sku: @product.sku, product_id: @product.id, club_id: @club.id) }
    @saved_user.fulfillments.each &:set_as_in_process

    set_as_undeliverable_user(@saved_user, 'reason')

    within('#table_demographic_information') do
      assert page.has_css?('tr.yellow')
    end
    @saved_user.reload.fulfillments do |fulfillment|
      assert_equal fulfillment.status, 'bad_address'
    end
  end

  test "Change fulfillment status from out_of_stock to bad_address after mark an user as 'wrong address'" do
    setup_user
    3.times { FactoryBot.create(:fulfillment, user_id: @saved_user.id, product_sku: @product.sku, product_id: @product.id, club_id: @club.id) }
    @saved_user.fulfillments.each &:set_as_out_of_stock

    set_as_undeliverable_user(@saved_user, 'reason')

    within('#table_demographic_information') do
      assert page.has_css?('tr.yellow')
    end
    @saved_user.reload.fulfillments do |fulfillment|
      assert_equal fulfillment.status, 'bad_address'
    end
  end

  test "Change fulfillment status from returned to bad_address after mark an user as 'wrong address'" do
    setup_user
    3.times { FactoryBot.create(:fulfillment, user_id: @saved_user.id, product_sku: @product.sku, product_id: @product.id, club_id: @club.id) }
    @saved_user.fulfillments.each &:set_as_returned

    set_as_undeliverable_user(@saved_user, 'reason')

    within('#table_demographic_information') do
      assert page.has_css?('tr.yellow')
    end
    @saved_user.reload

    @saved_user.fulfillments do |fulfillment|
      assert_equal fulfillment.status, 'bad_address'
    end
  end

  test 'Change fulfillment status from returned to not_processed when removing undeliverable' do
    setup_user
    FactoryBot.create(:fulfillment, user_id: @saved_user.id, product_sku: @product.sku, product_id: @product.id, club_id: @club.id)
    @saved_user.fulfillments.each { |x| x.update_status(nil, 'returned', 'testing') }
    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)

    within('#table_demographic_information') do
      assert page.has_css?('tr.yellow')
    end
    @saved_user.reload.fulfillments do |fulfillment|
      assert_equal fulfillment.status, 'returned'
    end
    click_link_or_button 'Edit'
    within('#table_demographic_information') { fill_in 'user[address]', with: 'new address 123' }

    alert_ok_js
    click_link_or_button 'Update User'
    @saved_user.reload.fulfillments do |fulfillment|
      assert_equal fulfillment.status, 'not_processed'
    end
  end

  test 'Change fulfillment status from bad_addres to not_processed when removing undeliverable' do
    setup_user
    FactoryBot.create(:fulfillment, user_id: @saved_user.id, product_sku: @product.sku, product_id: @product.id, club_id: @club.id)
    @saved_user.fulfillments.each { |x| x.update_status(nil, 'bad_address', 'testing') }
    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)

    within('#table_demographic_information') do
      assert page.has_css?('tr.yellow')
    end
    @saved_user.reload.fulfillments do |fulfillment|
      assert_equal fulfillment.status, 'bad_address'
    end
    click_link_or_button 'Edit'
    within('#table_demographic_information') do
      fill_in 'user[address]', with: 'new address 123'
    end

    alert_ok_js
    click_link_or_button 'Update User'
    @saved_user.reload.fulfillments do |fulfillment|
      assert_equal fulfillment.status, 'not_processed'
    end
  end
end
