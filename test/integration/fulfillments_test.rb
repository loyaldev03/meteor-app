require 'test_helper'

class FulfillmentsTest < ActionDispatch::IntegrationTest
  def setup_user(create_new_user = true)
    @admin_agent = FactoryBot.create(:confirmed_admin_agent)
    @club = FactoryBot.create(:simple_club_with_gateway)
    @terms_of_membership_with_gateway = FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club.id)

    @partner = @club.partner
    Time.zone = @club.time_zone

    @product = Product.find_by sku: Settings.others_product, club_id: @club.id

    if create_new_user
      @saved_user = create_active_user(@terms_of_membership_with_gateway, :active_user, nil, {}, created_by: @admin_agent)
      @fulfillment = FactoryBot.create(:fulfillment, user_id: @saved_user.id, product_sku: @product.sku, product_id: @product.id, club_id: @club.id)
    end

    sign_in_as(@admin_agent)
  end

  def create_user_throught_sloop(enrollment_info)
    @credit_card = FactoryBot.build :credit_card
    @user = FactoryBot.build :user_with_api
    create_user_by_sloop(@admin_agent, @user, @credit_card, enrollment_info, @terms_of_membership_with_gateway)
    @saved_user = User.last
  end

  def active_merchant_stub
    active_merchant_stubs_payeezy('100', 'Transaction Normal - Approved with Stub', true)
  end

  test 'display default data on fulfillments index' do
    setup_user(false)

    click_link_or_button('My Clubs')
    within('#my_clubs_table') do
      within('tr', text: @club.name, match: :prefer_exact) { click_on 'Fulfillments' }
    end
    page.has_content?('Fulfillments')

    within('#fulfillments_table') do
      assert find_field('initial_date').value == (Date.today - 1.week).to_s
      assert find_field('end_date').value == Date.today.to_s
      assert page.find_field('status').value == 'not_processed'
      assert page.find_field('all_times')
      assert page.has_content?('All')
    end
  end

  test 'fulfillment without stock (allow backorder as true).' do
    setup_user(false)
    @product.update_attributes(stock: 0, allow_backorder: true)
    enrollment_info = FactoryBot.build(:membership_with_enrollment_info, product_sku: @product.sku)

    create_user_throught_sloop(enrollment_info)
    @saved_user = User.find_by_email(@user.email)

    click_link_or_button('My Clubs')
    within('#my_clubs_table') do
      within('tr', text: @saved_user.club.name, match: :prefer_exact) { click_link_or_button 'Fulfillments' }
    end
    page.has_content?('Fulfillments')

    fulfillment = Fulfillment.find_by_product_sku(@product.sku)

    within('#fulfillments_table') do
      check('all_times')
      select('not_processed', from: 'status')
      choose('radio_product_filter_')
    end
    click_link_or_button('Report')
    within('#report_results') do
      assert page.has_content?(fulfillment.user.id)
      assert page.has_content?(fulfillment.user.full_name)
      assert page.has_content?(I18n.l(fulfillment.assigned_at, :format => :only_date))
      assert page.has_content?(fulfillment.product_sku)
      assert page.has_content?('not_processed')
    end
  end

  test "Search fulfillment at 'Not Processed' status by 'all times' checkbox and from Initial Date to End Date" do
    setup_user(false)
    active_merchant_stub
    enrollment_info = FactoryBot.build(:membership_with_enrollment_info)
    create_user_throught_sloop(enrollment_info)

    3.times { FactoryBot.create(:fulfillment, user_id: @saved_user.id, product_sku: @product.sku, product_id: @product.id, club_id: @club.id) }

    search_fulfillments(true)
    within('#report_results') do
      @saved_user.fulfillments.each do |fulfillment|
        assert page.has_content?(fulfillment.product_sku)
      end
      assert page.has_content?(@saved_user.full_name)
      assert page.has_content?(@saved_user.id.to_s)
      assert page.has_content?('not_processed')
    end

    search_fulfillments(false)
    within('#report_results') do
      @saved_user.fulfillments.each do |fulfillment|
        assert page.has_content?(fulfillment.product_sku)
      end
      assert page.has_content?(@saved_user.full_name)
      assert page.has_content?(@saved_user.id.to_s)
      assert page.has_content?('not_processed')
    end
  end

  test "Search fulfillment at 'Manual Review Required' status by 'all times' checkbox and from Initial Date to End Date" do
    setup_user(false)
    active_merchant_stub
    enrollment_info = FactoryBot.build(:membership_with_enrollment_info)
    create_user_throught_sloop(enrollment_info)

    3.times { FactoryBot.create(:fulfillment, user_id: @saved_user.id, product_sku: @product.sku, product_id: @product.id, club_id: @club.id) }

    @saved_user.fulfillments.each &:set_as_manual_review_required

    search_fulfillments(true, nil, nil, 'manual_review_required')
    within('#report_results') do
      @saved_user.fulfillments.each do |fulfillment|
        assert page.has_content?(fulfillment.product_sku)
      end
      assert page.has_content?(@saved_user.full_name)
      assert page.has_content?(@saved_user.id.to_s)
      assert page.has_content?('manual_review_required')
    end

    search_fulfillments(false, nil, nil, 'manual_review_required')
    within('#report_results') do
      @saved_user.fulfillments.each do |fulfillment|
        assert page.has_content?(fulfillment.product_sku)
      end
      assert page.has_content?(@saved_user.full_name)
      assert page.has_content?(@saved_user.id.to_s)
      assert page.has_content?('manual_review_required')
    end
  end

  test "Search fulfillment at 'In Process' status by 'all times' checkbox and from Initial Date to End Date" do
    setup_user(false)
    active_merchant_stub
    enrollment_info = FactoryBot.build(:membership_with_enrollment_info)
    create_user_throught_sloop(enrollment_info)

    3.times { FactoryBot.create(:fulfillment, user_id: @saved_user.id, product_sku: @product.sku, product_id: @product.id, club_id: @club.id) }

    @saved_user.fulfillments.each &:set_as_in_process

    search_fulfillments(true, nil, nil, 'in_process')
    within('#report_results') do
      @saved_user.fulfillments.each do |fulfillment|
        assert page.has_content?(fulfillment.product_sku)
      end
      assert page.has_content?(@saved_user.full_name)
      assert page.has_content?(@saved_user.id.to_s)
      assert page.has_content?('in_process')
    end

    search_fulfillments(false, nil, nil, 'in_process')
    within('#report_results') do
      @saved_user.fulfillments.each do |fulfillment|
        assert page.has_content?(fulfillment.product_sku)
      end
      assert page.has_content?(@saved_user.full_name)
      assert page.has_content?(@saved_user.id.to_s)
      assert page.has_content?('in_process')
    end
  end

  test "Search fulfillment at 'On Hold' status by 'all times' checkbox and from Initial Date to End Date" do
    setup_user(false)
    active_merchant_stub
    enrollment_info = FactoryBot.build(:membership_with_enrollment_info)
    create_user_throught_sloop(enrollment_info)

    3.times { FactoryBot.create(:fulfillment, user_id: @saved_user.id, product_sku: @product.sku, product_id: @product.id, club_id: @club.id) }

    @saved_user.fulfillments.each &:set_as_on_hold

    search_fulfillments(true, nil, nil, 'on_hold')
    within('#report_results') do
      @saved_user.fulfillments.each do |fulfillment|
        assert page.has_content?(fulfillment.product_sku)
      end
      assert page.has_content?(@saved_user.full_name)
      assert page.has_content?(@saved_user.id.to_s)
      assert page.has_content?('on_hold')
    end

    search_fulfillments(false, nil, nil, 'on_hold')
    within('#report_results') do
      @saved_user.fulfillments.each do |fulfillment|
        assert page.has_content?(fulfillment.product_sku)
      end
      assert page.has_content?(@saved_user.full_name)
      assert page.has_content?(@saved_user.id.to_s)
      assert page.has_content?('on_hold')
    end
  end

  test "Search fulfillment at 'Out of Stock' status by 'all times' checkbox and from Initial Date to End Date" do
    setup_user(false)
    active_merchant_stub
    enrollment_info = FactoryBot.build(:membership_with_enrollment_info)
    create_user_throught_sloop(enrollment_info)

    3.times { FactoryBot.create(:fulfillment, user_id: @saved_user.id, product_sku: @product.sku, product_id: @product.id, club_id: @club.id) }

    @saved_user.fulfillments.each &:set_as_out_of_stock

    search_fulfillments(true, nil, nil, 'out_of_stock')
    within('#report_results') do
      @saved_user.fulfillments.each do |fulfillment|
        assert page.has_content?(fulfillment.product_sku)
      end
      assert page.has_content?(@saved_user.full_name)
      assert page.has_content?(@saved_user.id.to_s)
      assert page.has_content?('out_of_stock')
    end

    search_fulfillments(false, nil, nil, 'out_of_stock')
    within('#report_results') do
      @saved_user.fulfillments.each do |fulfillment|
        assert page.has_content?(fulfillment.product_sku)
      end
      assert page.has_content?(@saved_user.full_name)
      assert page.has_content?(@saved_user.id.to_s)
      assert page.has_content?('out_of_stock')
    end
  end

  test "Search fulfillment at 'Returned' status by 'all times' checkbox and from Initial Date to End Date" do
    setup_user(false)
    active_merchant_stub
    enrollment_info = FactoryBot.build(:membership_with_enrollment_info)
    create_user_throught_sloop(enrollment_info)

    3.times { FactoryBot.create(:fulfillment, user_id: @saved_user.id, product_sku: @product.sku, product_id: @product.id, club_id: @club.id) }

    @saved_user.fulfillments.each &:set_as_returned

    search_fulfillments(true, nil, nil, 'returned')
    within('#report_results') do
      @saved_user.fulfillments.each do |fulfillment|
        assert page.has_content?(fulfillment.product_sku)
      end
      assert page.has_content?(@saved_user.full_name)
      assert page.has_content?(@saved_user.id.to_s)
      assert page.has_content?('returned')
    end

    search_fulfillments(false, nil, nil, 'returned')
    within('#report_results') do
      @saved_user.fulfillments.each do |fulfillment|
        assert page.has_content?(fulfillment.product_sku)
      end
      assert page.has_content?(@saved_user.full_name)
      assert page.has_content?(@saved_user.id.to_s)
      assert page.has_content?('returned')
    end
  end

  test "Search fulfillment at 'Sent' status by 'all times' checkbox and from Initial Date to End Date" do
    setup_user(false)
    active_merchant_stub
    enrollment_info = FactoryBot.build(:membership_with_enrollment_info)
    create_user_throught_sloop(enrollment_info)

    3.times { FactoryBot.create(:fulfillment, user_id: @saved_user.id, product_sku: @product.sku, product_id: @product.id, club_id: @club.id) }

    @saved_user.fulfillments.each &:set_as_sent

    search_fulfillments(true, nil, nil, 'sent')
    within('#report_results') do
      @saved_user.fulfillments.each do |fulfillment|
        assert page.has_content?(fulfillment.product_sku)
      end
      assert page.has_content?(@saved_user.full_name)
      assert page.has_content?(@saved_user.id.to_s)
      assert page.has_content?('sent')
    end

    search_fulfillments(false, nil, nil, 'sent')
    within('#report_results') do
      @saved_user.fulfillments.each do |fulfillment|
        assert page.has_content?(fulfillment.product_sku)
      end
      assert page.has_content?(@saved_user.full_name)
      assert page.has_content?(@saved_user.id.to_s)
      assert page.has_content?('sent')
    end
  end

  test "Search fulfillment at 'Bad address' status by 'all times' checkbox and from Initial Date to End Date" do
    setup_user(false)
    active_merchant_stub
    enrollment_info = FactoryBot.build(:membership_with_enrollment_info)
    create_user_throught_sloop(enrollment_info)

    3.times { FactoryBot.create(:fulfillment, user_id: @saved_user.id, product_sku: @product.sku, product_id: @product.id, club_id: @club.id) }

    @saved_user.fulfillments.each &:set_as_bad_address

    search_fulfillments(true, nil, nil, 'bad_address')
    within('#report_results') do
      @saved_user.fulfillments.each do |fulfillment|
        assert page.has_content?(fulfillment.product_sku)
      end
      assert page.has_content?(@saved_user.full_name)
      assert page.has_content?(@saved_user.id.to_s)
      assert page.has_content?('bad_address')
    end

    search_fulfillments(false, nil, nil, 'bad_address')
    within('#report_results') do
      @saved_user.fulfillments.each do |fulfillment|
        assert page.has_content?(fulfillment.product_sku)
      end
      assert page.has_content?(@saved_user.full_name)
      assert page.has_content?(@saved_user.id.to_s)
      assert page.has_content?('bad_address')
    end
  end

  test 'Update the status of all the fulfillments from in_process selecting the All results checkbox' do
    setup_user(false)
    active_merchant_stub
    enrollment_info = FactoryBot.build(:membership_with_enrollment_info)
    create_user_throught_sloop(enrollment_info)

    3.times { FactoryBot.create(:fulfillment, user_id: @saved_user.id, product_sku: @product.sku, product_id: @product.id, club_id: @club.id) }
    @saved_user.fulfillments.each &:set_as_in_process

    search_fulfillments(false, nil, nil, 'in_process')
    update_status_on_fulfillments(@saved_user.fulfillments, 'not_processed', true)
    @saved_user.reload
    @saved_user.fulfillments.each &:set_as_in_process

    search_fulfillments(false, nil, nil, 'in_process')
    update_status_on_fulfillments(@saved_user.fulfillments, 'on_hold', true)
    @saved_user.reload
    @saved_user.fulfillments.each &:set_as_in_process
    search_fulfillments(false, nil, nil, 'in_process')
    update_status_on_fulfillments(@saved_user.fulfillments, 'sent', true)
    @saved_user.reload
    @saved_user.fulfillments.each &:set_as_in_process

    search_fulfillments(false, nil, nil, 'in_process')
    update_status_on_fulfillments(@saved_user.fulfillments, 'returned', true)
    @saved_user.reload
    @saved_user.fulfillments.each &:set_as_in_process

    search_fulfillments(false, nil, nil, 'in_process')
    update_status_on_fulfillments(@saved_user.fulfillments, 'bad_address', true)
    @saved_user.reload
    @saved_user.fulfillments.each &:set_as_in_process

    search_fulfillments(false, nil, nil, 'in_process')
    @saved_user.reload
    update_status_on_fulfillments(@saved_user.fulfillments, 'out_of_stock', true)
    @saved_user.reload
    @saved_user.fulfillments.each &:set_as_in_process
  end

  test 'Update the status of all the fulfillments from not_processed selecting the All results checkbox' do
    setup_user(false)
    active_merchant_stub
    enrollment_info = FactoryBot.build(:membership_with_enrollment_info)
    create_user_throught_sloop(enrollment_info)

    3.times { FactoryBot.create(:fulfillment, user_id: @saved_user.id, product_sku: @product.sku, product_id: @product.id, club_id: @club.id) }

    search_fulfillments(false, nil, nil, 'not_processed')
    update_status_on_fulfillments(@saved_user.fulfillments, 'in_process', true)
    @saved_user.reload
    @saved_user.fulfillments.each &:set_as_not_processed

    search_fulfillments(false, nil, nil, 'not_processed')
    update_status_on_fulfillments(@saved_user.fulfillments, 'on_hold', true)
    @saved_user.reload
    @saved_user.fulfillments.each &:set_as_not_processed
    search_fulfillments(false, nil, nil, 'not_processed')
    update_status_on_fulfillments(@saved_user.fulfillments, 'sent', true)
    @saved_user.reload
    @saved_user.fulfillments.each &:set_as_not_processed
    search_fulfillments(false, nil, nil, 'not_processed')
    update_status_on_fulfillments(@saved_user.fulfillments, 'returned', true)
    @saved_user.reload
    @saved_user.fulfillments.each &:set_as_not_processed
    search_fulfillments(false, nil, nil, 'not_processed')
    update_status_on_fulfillments(@saved_user.fulfillments, 'bad_address', true)
    @saved_user.reload
    @saved_user.fulfillments.each &:set_as_not_processed
    search_fulfillments(false, nil, nil, 'not_processed')
    @saved_user.reload
    update_status_on_fulfillments(@saved_user.fulfillments, 'out_of_stock', true)
    @saved_user.reload
    @saved_user.fulfillments.each &:set_as_not_processed

    search_fulfillments(false, nil, nil, 'not_processed')
    @saved_user.reload
    update_status_on_fulfillments(@saved_user.fulfillments, 'manual_review_required', true)
  end

  test 'Update the status of all the fulfillments from on_hold selecting the All results checkbox' do
    setup_user(false)
    active_merchant_stub
    enrollment_info = FactoryBot.build(:membership_with_enrollment_info)
    create_user_throught_sloop(enrollment_info)

    3.times { FactoryBot.create(:fulfillment, user_id: @saved_user.id, product_sku: @product.sku, product_id: @product.id, club_id: @club.id) }
    @saved_user.fulfillments.each &:set_as_on_hold

    search_fulfillments(false, nil, nil, 'on_hold')
    update_status_on_fulfillments(@saved_user.fulfillments, 'in_process', true)
    @saved_user.reload
    @saved_user.fulfillments.each &:set_as_on_hold

    search_fulfillments(false, nil, nil, 'on_hold')
    update_status_on_fulfillments(@saved_user.fulfillments, 'not_processed', true)
    @saved_user.reload
    @saved_user.fulfillments.each &:set_as_on_hold
    search_fulfillments(false, nil, nil, 'on_hold')
    update_status_on_fulfillments(@saved_user.fulfillments, 'sent', true)
    @saved_user.reload
    @saved_user.fulfillments.each &:set_as_on_hold
    search_fulfillments(false, nil, nil, 'on_hold')
    update_status_on_fulfillments(@saved_user.fulfillments, 'returned', true)
    @saved_user.reload
    @saved_user.fulfillments.each &:set_as_on_hold
    search_fulfillments(false, nil, nil, 'on_hold')
    update_status_on_fulfillments(@saved_user.fulfillments, 'bad_address', true)
    @saved_user.reload
    @saved_user.fulfillments.each &:set_as_on_hold
    search_fulfillments(false, nil, nil, 'on_hold')
    @saved_user.reload
    update_status_on_fulfillments(@saved_user.fulfillments, 'out_of_stock', true)
  end

  test 'Update the status of all the fulfillments from sent selecting the All results checkbox' do
    setup_user(false)
    active_merchant_stub
    enrollment_info = FactoryBot.build(:membership_with_enrollment_info)
    create_user_throught_sloop(enrollment_info)

    3.times { FactoryBot.create(:fulfillment, user_id: @saved_user.id, product_sku: @product.sku, product_id: @product.id, club_id: @club.id) }
    @saved_user.fulfillments.each &:set_as_sent

    search_fulfillments(false, nil, nil, 'sent')
    update_status_on_fulfillments(@saved_user.fulfillments, 'in_process', true)
    @saved_user.reload
    @saved_user.fulfillments.each &:set_as_sent

    search_fulfillments(false, nil, nil, 'sent')
    update_status_on_fulfillments(@saved_user.fulfillments, 'not_processed', true)
    @saved_user.reload
    @saved_user.fulfillments.each &:set_as_sent
    search_fulfillments(false, nil, nil, 'sent')
    update_status_on_fulfillments(@saved_user.fulfillments, 'on_hold', true)
    @saved_user.reload
    @saved_user.fulfillments.each &:set_as_sent
    search_fulfillments(false, nil, nil, 'sent')
    update_status_on_fulfillments(@saved_user.fulfillments, 'returned', true)
    @saved_user.reload
    @saved_user.fulfillments.each &:set_as_sent
    search_fulfillments(false, nil, nil, 'sent')
    update_status_on_fulfillments(@saved_user.fulfillments, 'bad_address', true)
    @saved_user.reload
    @saved_user.fulfillments.each &:set_as_sent
    search_fulfillments(false, nil, nil, 'sent')
    @saved_user.reload
    update_status_on_fulfillments(@saved_user.fulfillments, 'out_of_stock', true)
  end

  test 'Update the status of all the fulfillments from out_of_stock selecting the All results checkbox' do
    setup_user(false)
    active_merchant_stub
    enrollment_info = FactoryBot.build(:membership_with_enrollment_info)
    create_user_throught_sloop(enrollment_info)

    3.times { FactoryBot.create(:fulfillment, user_id: @saved_user.id, product_sku: @product.sku, product_id: @product.id, club_id: @club.id) }
    @saved_user.fulfillments.each &:set_as_out_of_stock

    search_fulfillments(false, nil, nil, 'out_of_stock')
    update_status_on_fulfillments(@saved_user.fulfillments, 'in_process', true)
    @saved_user.reload
    @saved_user.fulfillments.each &:set_as_out_of_stock

    search_fulfillments(false, nil, nil, 'out_of_stock')
    update_status_on_fulfillments(@saved_user.fulfillments, 'not_processed', true)
    @saved_user.reload
    @saved_user.fulfillments.each &:set_as_out_of_stock
    search_fulfillments(false, nil, nil, 'out_of_stock')
    update_status_on_fulfillments(@saved_user.fulfillments, 'on_hold', true)
    @saved_user.reload
    @saved_user.fulfillments.each &:set_as_out_of_stock
    search_fulfillments(false, nil, nil, 'out_of_stock')
    update_status_on_fulfillments(@saved_user.fulfillments, 'returned', true)
    @saved_user.reload
    @saved_user.fulfillments.each &:set_as_out_of_stock
    search_fulfillments(false, nil, nil, 'out_of_stock')
    update_status_on_fulfillments(@saved_user.fulfillments, 'bad_address', true)
    @saved_user.reload
    @saved_user.fulfillments.each &:set_as_out_of_stock
    search_fulfillments(false, nil, nil, 'out_of_stock')
    @saved_user.reload
    update_status_on_fulfillments(@saved_user.fulfillments, 'sent', true)
  end

  test 'Update the status of all the fulfillments from returned selecting the All results checkbox' do
    setup_user(false)
    active_merchant_stub
    enrollment_info = FactoryBot.build(:membership_with_enrollment_info)
    create_user_throught_sloop(enrollment_info)

    3.times { FactoryBot.create(:fulfillment, user_id: @saved_user.id, product_sku: @product.sku, product_id: @product.id, club_id: @club.id) }
    @saved_user.fulfillments.each &:set_as_returned

    search_fulfillments(false, nil, nil, 'returned')
    update_status_on_fulfillments(@saved_user.fulfillments, 'in_process', true)
    @saved_user.reload
    @saved_user.fulfillments.each &:set_as_returned

    search_fulfillments(false, nil, nil, 'returned')
    update_status_on_fulfillments(@saved_user.fulfillments, 'not_processed', true)
    @saved_user.reload
    @saved_user.fulfillments.each &:set_as_returned

    search_fulfillments(false, nil, nil, 'returned')
    update_status_on_fulfillments(@saved_user.fulfillments, 'on_hold', true)
    @saved_user.reload
    @saved_user.fulfillments.each &:set_as_returned

    search_fulfillments(false, nil, nil, 'returned')
    update_status_on_fulfillments(@saved_user.fulfillments, 'out_of_stock', true)
    @saved_user.reload
    @saved_user.fulfillments.each &:set_as_returned

    search_fulfillments(false, nil, nil, 'returned')
    update_status_on_fulfillments(@saved_user.fulfillments, 'bad_address', true)
    @saved_user.reload
    @saved_user.fulfillments.each &:set_as_returned

    search_fulfillments(false, nil, nil, 'returned')
    @saved_user.reload
    update_status_on_fulfillments(@saved_user.fulfillments, 'sent', true)
  end

  test 'Update the status of all the fulfillments from bad_address selecting the All results checkbox' do
    setup_user(false)
    active_merchant_stub
    enrollment_info = FactoryBot.build(:membership_with_enrollment_info)
    create_user_throught_sloop(enrollment_info)

    3.times { FactoryBot.create(:fulfillment, user_id: @saved_user.id, product_sku: @product.sku, product_id: @product.id, club_id: @club.id) }
    @saved_user.fulfillments.each &:set_as_bad_address

    search_fulfillments(false, nil, nil, 'bad_address')
    update_status_on_fulfillments(@saved_user.fulfillments, 'in_process', true)
    @saved_user.reload
    @saved_user.fulfillments.each &:set_as_bad_address

    search_fulfillments(false, nil, nil, 'bad_address')
    update_status_on_fulfillments(@saved_user.fulfillments, 'not_processed', true)
    @saved_user.reload
    @saved_user.fulfillments.each &:set_as_bad_address

    search_fulfillments(false, nil, nil, 'bad_address')
    update_status_on_fulfillments(@saved_user.fulfillments, 'on_hold', true)
    @saved_user.reload
    @saved_user.fulfillments.each &:set_as_bad_address

    search_fulfillments(false, nil, nil, 'bad_address')
    update_status_on_fulfillments(@saved_user.fulfillments, 'out_of_stock', true)
    @saved_user.reload
    @saved_user.fulfillments.each &:set_as_bad_address

    search_fulfillments(false, nil, nil, 'bad_address')
    update_status_on_fulfillments(@saved_user.fulfillments, 'returned', true)
    @saved_user.reload
    @saved_user.fulfillments.each &:set_as_bad_address

    search_fulfillments(false, nil, nil, 'bad_address')
    @saved_user.reload
    update_status_on_fulfillments(@saved_user.fulfillments, 'sent', true)
  end

  test 'Update the status of the fulfillments not processed using individual checkboxes' do
    setup_user(false)
    active_merchant_stub
    enrollment_info = FactoryBot.build(:membership_with_enrollment_info)
    create_user_throught_sloop(enrollment_info)

    5.times { FactoryBot.create(:fulfillment, user_id: @saved_user.id, product_sku: @product.sku, product_id: @product.id, club_id: @club.id) }

    fulfillments = @saved_user.fulfillments
    search_fulfillments(false, nil, nil, 'not_processed')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[0]
    update_status_on_fulfillments(fulfillment_to_update, 'in_process')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[1]
    update_status_on_fulfillments(fulfillment_to_update, 'on_hold')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[2]
    update_status_on_fulfillments(fulfillment_to_update, 'out_of_stock')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[3]
    update_status_on_fulfillments(fulfillment_to_update, 'returned')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[4]
    update_status_on_fulfillments(fulfillment_to_update, 'sent')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[5]
    update_status_on_fulfillments(fulfillment_to_update, 'bad_address')
  end

  test 'Update the status of all the fulfillments in_process using individual checkboxes' do
    setup_user(false)
    active_merchant_stub
    enrollment_info = FactoryBot.build(:membership_with_enrollment_info)
    create_user_throught_sloop(enrollment_info)

    5.times { FactoryBot.create(:fulfillment, user_id: @saved_user.id, product_sku: @product.sku, product_id: @product.id, club_id: @club.id) }
    @saved_user.fulfillments.each &:set_as_in_process

    fulfillments = @saved_user.fulfillments
    search_fulfillments(false, nil, nil, 'in_process')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[0]
    update_status_on_fulfillments(fulfillment_to_update, 'not_processed')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[1]
    update_status_on_fulfillments(fulfillment_to_update, 'on_hold')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[2]
    update_status_on_fulfillments(fulfillment_to_update, 'out_of_stock')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[3]
    update_status_on_fulfillments(fulfillment_to_update, 'returned')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[4]
    update_status_on_fulfillments(fulfillment_to_update, 'sent')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[5]
    update_status_on_fulfillments(fulfillment_to_update, 'bad_address')
  end

  test 'Update the status of all the fulfillments on_hold using individual checkboxes' do
    setup_user(false)
    active_merchant_stub
    enrollment_info = FactoryBot.build(:membership_with_enrollment_info)
    create_user_throught_sloop(enrollment_info)

    5.times { FactoryBot.create(:fulfillment, user_id: @saved_user.id, product_sku: @product.sku, product_id: @product.id, club_id: @club.id) }
    @saved_user.fulfillments.each &:set_as_on_hold

    fulfillments = @saved_user.fulfillments
    search_fulfillments(false, nil, nil, 'on_hold')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[0]
    update_status_on_fulfillments(fulfillment_to_update, 'not_processed')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[1]
    update_status_on_fulfillments(fulfillment_to_update, 'in_process')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[2]
    update_status_on_fulfillments(fulfillment_to_update, 'out_of_stock')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[3]
    update_status_on_fulfillments(fulfillment_to_update, 'returned')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[4]
    update_status_on_fulfillments(fulfillment_to_update, 'sent')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[5]
    update_status_on_fulfillments(fulfillment_to_update, 'bad_address')
  end

  test 'Update the status of all the fulfillments sent using individual checkboxes' do
    setup_user(false)
    active_merchant_stub
    enrollment_info = FactoryBot.build(:membership_with_enrollment_info)
    create_user_throught_sloop(enrollment_info)

    5.times { FactoryBot.create(:fulfillment, user_id: @saved_user.id, product_sku: @product.sku, product_id: @product.id, club_id: @club.id) }
    @saved_user.fulfillments.each &:set_as_sent

    fulfillments = @saved_user.fulfillments
    search_fulfillments(false, nil, nil, 'sent')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[0]
    update_status_on_fulfillments(fulfillment_to_update, 'not_processed')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[1]
    update_status_on_fulfillments(fulfillment_to_update, 'in_process')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[2]
    update_status_on_fulfillments(fulfillment_to_update, 'out_of_stock')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[3]
    update_status_on_fulfillments(fulfillment_to_update, 'returned')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[4]
    update_status_on_fulfillments(fulfillment_to_update, 'on_hold')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[5]
    update_status_on_fulfillments(fulfillment_to_update, 'bad_address')
  end

  test 'Update the status of all the fulfillments out_of_stock using individual checkboxes' do
    setup_user(false)
    active_merchant_stub
    enrollment_info = FactoryBot.build(:membership_with_enrollment_info)
    create_user_throught_sloop(enrollment_info)

    5.times { FactoryBot.create(:fulfillment, user_id: @saved_user.id, product_sku: @product.sku, product_id: @product.id, club_id: @club.id) }
    @saved_user.fulfillments.each &:set_as_out_of_stock

    fulfillments = @saved_user.fulfillments
    search_fulfillments(false, nil, nil, 'out_of_stock')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[0]
    update_status_on_fulfillments(fulfillment_to_update, 'not_processed')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[1]
    update_status_on_fulfillments(fulfillment_to_update, 'in_process')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[2]
    update_status_on_fulfillments(fulfillment_to_update, 'sent')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[3]
    update_status_on_fulfillments(fulfillment_to_update, 'returned')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[4]
    update_status_on_fulfillments(fulfillment_to_update, 'on_hold')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[5]
    update_status_on_fulfillments(fulfillment_to_update, 'bad_address')
  end

  test 'Update the status of all the fulfillments returned using individual checkboxes' do
    setup_user(false)
    active_merchant_stub
    enrollment_info = FactoryBot.build(:membership_with_enrollment_info)
    create_user_throught_sloop(enrollment_info)

    5.times { FactoryBot.create(:fulfillment, user_id: @saved_user.id, product_sku: @product.sku, product_id: @product.id, club_id: @club.id) }
    @saved_user.fulfillments.each &:set_as_returned

    fulfillments = @saved_user.fulfillments
    search_fulfillments(false, nil, nil, 'returned')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[0]
    update_status_on_fulfillments(fulfillment_to_update, 'not_processed')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[1]
    update_status_on_fulfillments(fulfillment_to_update, 'in_process')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[2]
    update_status_on_fulfillments(fulfillment_to_update, 'sent')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[3]
    update_status_on_fulfillments(fulfillment_to_update, 'out_of_stock')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[4]
    update_status_on_fulfillments(fulfillment_to_update, 'on_hold')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[5]
    update_status_on_fulfillments(fulfillment_to_update, 'bad_address')
  end

  test 'Update the status of all the fulfillments bad_address using individual checkboxes' do
    setup_user(false)
    active_merchant_stub
    enrollment_info = FactoryBot.build(:membership_with_enrollment_info)
    create_user_throught_sloop(enrollment_info)

    5.times { FactoryBot.create(:fulfillment, user_id: @saved_user.id, product_sku: @product.sku, product_id: @product.id, club_id: @club.id) }
    @saved_user.fulfillments.each &:set_as_bad_address

    fulfillments = @saved_user.fulfillments
    search_fulfillments(false, nil, nil, 'bad_address')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[0]
    update_status_on_fulfillments(fulfillment_to_update, 'not_processed')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[1]
    update_status_on_fulfillments(fulfillment_to_update, 'in_process')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[2]
    update_status_on_fulfillments(fulfillment_to_update, 'sent')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[3]
    update_status_on_fulfillments(fulfillment_to_update, 'out_of_stock')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[4]
    update_status_on_fulfillments(fulfillment_to_update, 'on_hold')

    fulfillment_to_update = []
    fulfillment_to_update << fulfillments[5]
    update_status_on_fulfillments(fulfillment_to_update, 'returned')
  end

  test 'Error message if changing from one status to same status' do
    setup_user(false)
    active_merchant_stub
    enrollment_info = FactoryBot.build(:membership_with_enrollment_info)
    create_user_throught_sloop(enrollment_info)

    @saved_user.fulfillments
    search_fulfillments(false, nil, nil, 'not_processed')

    alert_ok_js
    update_status_on_fulfillments(@saved_user.fulfillments, 'not_processed', false, false)
    within('#report_results') { assert page.has_content?("Nothing to change on #{Settings.others_product} fulfillment.") }
  end

  test "Error message if changing from one status to 'blank' status" do
    setup_user(false)
    active_merchant_stub
    enrollment_info = FactoryBot.build(:membership_with_enrollment_info)
    create_user_throught_sloop(enrollment_info)

    fulfillments = @saved_user.fulfillments
    search_fulfillments(false, nil, nil, 'not_processed')

    alert_ok_js
    within('#report_results') do
      check "fulfillment_selected[#{fulfillments[0].id}]"
      click_link_or_button 'Update status'
    end

    within('#report_results') { assert page.has_content?('New status is blank. Please, select a new status to be applied.') }
  end

  test 'Search fulfillments by sku selecting all times checkbox' do
    setup_user(false)
    active_merchant_stub
    enrollment_info = FactoryBot.build(:membership_with_enrollment_info)
    create_user_throught_sloop(enrollment_info)

    product1 = FactoryBot.create(:product, club_id: @saved_user.club_id, sku: 'NCARFLAGBRACELET1')
    product2 = FactoryBot.create(:product, club_id: @saved_user.club_id, sku: 'NCARFLAGBRACELET2')
    product3 = FactoryBot.create(:product, club_id: @saved_user.club_id, sku: 'NCARFLAGTWOBRACELET3')
    product4 = FactoryBot.create(:product, club_id: @saved_user.club_id, sku: 'NCARFLAGTWOBRACELET4')

    2.times { FactoryBot.create(:fulfillment, user_id: @saved_user.id, product_sku: 'NCARFLAGBRACELET1', product_id: product1.id, club_id: @club.id) }
    2.times { FactoryBot.create(:fulfillment, user_id: @saved_user.id, product_sku: 'NCARFLAGBRACELET2', product_id: product2.id, club_id: @club.id) }
    2.times { FactoryBot.create(:fulfillment, user_id: @saved_user.id, product_sku: 'NCARFLAGTWOBRACELET3', product_id: product3.id, club_id: @club.id) }
    2.times { FactoryBot.create(:fulfillment, user_id: @saved_user.id, product_sku: 'NCARFLAGTWOBRACELET4', product_id: product4.id, club_id: @club.id) }

    search_fulfillments(true, nil, nil, nil, nil, 'NCARFLAG')
    within('#report_results') do
      assert page.has_content? 'NCARFLAGBRACELET1'
      assert page.has_content? 'NCARFLAGBRACELET2'
      assert page.has_content? 'NCARFLAGTWOBRACELET3'
      assert page.has_content? 'NCARFLAGTWOBRACELET4'
    end

    search_fulfillments(true, nil, nil, nil, nil, 'NCARFLAGTWO')
    within('#report_results') do
      assert page.has_no_content? 'NCARFLAGBRACELET1'
      assert page.has_no_content? 'NCARFLAGBRACELET2'
      assert page.has_content? 'NCARFLAGTWOBRACELET3'
      assert page.has_content? 'NCARFLAGTWOBRACELET4'
    end
  end

  test 'Search Fulfillments by sku selecting dates' do
    setup_user(false)
    active_merchant_stub
    enrollment_info = FactoryBot.build(:membership_with_enrollment_info)
    create_user_throught_sloop(enrollment_info)

    product1 = FactoryBot.create(:product, club_id: @saved_user.club_id, sku: 'NCARFLAGBRACELET1')
    product2 = FactoryBot.create(:product, club_id: @saved_user.club_id, sku: 'NCARFLAGBRACELET2')
    product3 = FactoryBot.create(:product, club_id: @saved_user.club_id, sku: 'NCARFLAGTWOBRACELET3')
    product4 = FactoryBot.create(:product, club_id: @saved_user.club_id, sku: 'NCARFLAGTWOBRACELET4')

    2.times { FactoryBot.create(:fulfillment, user_id: @saved_user.id, product_sku: 'NCARFLAGBRACELET1', product_id: product1.id, club_id: @club.id) }
    2.times { FactoryBot.create(:fulfillment, user_id: @saved_user.id, product_sku: 'NCARFLAGBRACELET2', product_id: product2.id, club_id: @club.id) }
    2.times { FactoryBot.create(:fulfillment, user_id: @saved_user.id, product_sku: 'NCARFLAGTWOBRACELET3', product_id: product3.id, club_id: @club.id) }
    2.times { FactoryBot.create(:fulfillment, user_id: @saved_user.id, product_sku: 'NCARFLAGTWOBRACELET4', product_id: product4.id, club_id: @club.id) }

    search_fulfillments(false, nil, nil, nil, nil, 'NCARFLAG')
    within('#report_results') do
      assert page.has_content? 'NCARFLAGBRACELET1'
      assert page.has_content? 'NCARFLAGBRACELET2'
      assert page.has_content? 'NCARFLAGTWOBRACELET3'
      assert page.has_content? 'NCARFLAGTWOBRACELET4'
    end

    search_fulfillments(false, nil, nil, nil, nil, 'NCARFLAGTWO')
    within('#report_results') do
      assert page.has_no_content? 'NCARFLAGBRACELET1'
      assert page.has_no_content? 'NCARFLAGBRACELET2'
      assert page.has_content? 'NCARFLAGTWOBRACELET3'
      assert page.has_content? 'NCARFLAGTWOBRACELET4'
    end
  end

  test 'not_processed and in_process fulfillments should be updated to bad_address when set_wrong_address' do
    setup_user(false)
    enrollment_info = FactoryBot.build(:membership_with_enrollment_info)

    create_user_throught_sloop(enrollment_info)
    @saved_user = User.find_by_email(@user.email)
    fulfillment = Fulfillment.find_by(product_sku: Settings.others_product)
    fulfillment.set_as_not_processed
    @saved_user.set_wrong_address(@admin_agent, 'reason')

    visit fulfillments_index_path(partner_prefix: @partner.prefix, club_prefix: @club.name)

    page.has_content?('Fulfillments')
    within('#fulfillments_table') do
      check('all_times')
      select('bad_address', from: 'status')
      choose('radio_product_filter_')
    end
    click_link_or_button('Report')
    within('#report_results') do
      assert page.has_content?('bad_address')
      assert page.has_content?(Settings.others_product)
    end

    @saved_user.address = 'random address'
    @saved_user.save
    fulfillment.set_as_in_process
    @saved_user.set_wrong_address(@admin_agent, 'reason')

    within('#fulfillments_table') do
      check('all_times')
      select('bad_address', from: 'status')
      choose('radio_product_filter_')
    end
    click_link_or_button('Report')
    within('#report_results') do
      assert page.has_content?('bad_address')
      assert page.has_content?(Settings.others_product)
    end
  end
end
