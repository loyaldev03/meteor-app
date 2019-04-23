require 'test_helper'

class FulfillmentFilesTest < ActionDispatch::IntegrationTest
  def setup_user(create_new_user = true)
    @admin_agent = FactoryBot.create(:confirmed_admin_agent)
    @club = FactoryBot.create(:simple_club_with_gateway)
    @terms_of_membership_with_gateway = FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club.id)
    @partner = @club.partner
    Time.zone = @club.time_zone

    @product = Product.find_by sku: Settings.others_product, club_id: @club.id

    if create_new_user
      @saved_user   = enroll_user(FactoryBot.build(:user), @terms_of_membership_with_gateway)
      @fulfillment  = @saved_user.fulfillments.find_by(product_sku: @product.sku)
    end

    sign_in_as(@admin_agent)
  end

  def create_user_throught_sloop(enrollment_info)
    @saved_user = create_user_by_sloop(@admin_agent, FactoryBot.build(:user_with_api), @credit_card, FactoryBot.build(:credit_card), @terms_of_membership_with_gateway)
  end

  def generate_fulfillment_files(all_times = true, fulfillments = nil, initial_date = nil, end_date = nil, _status = 'not_processed', validate = true)
    search_fulfillments(all_times, initial_date, end_date, 'not_processed')
    within('#report_results') do
      assert page.has_selector?('#create_xls_file')
      if fulfillments.nil?
        check 'fulfillment_select_all'
      else
        fulfillments.each do |fulfillment|
          check "fulfillment_selected[#{fulfillment.id}]"
        end
      end
      click_link_or_button 'Create XLS File'
    end
    if validate
      assert page.has_content?('File created succesfully')
      fulfillment_file = FulfillmentFile.last
      visit list_fulfillment_files_path(partner_prefix: @partner.prefix, club_prefix: @club.name)

      within('#fulfillment_files_table') do
        assert page.has_content?(fulfillment_file.id.to_s)
        assert page.has_content?(fulfillment_file.status)
        assert page.has_content?(fulfillment_file.product)
        assert page.has_content?(fulfillment_file.dates)
        assert page.has_content?(fulfillment_file.fulfillments_processed)
        assert page.has_selector?("#mark_as_packed_#{fulfillment_file.id}") if fulfillment_file.status == 'in_process'
        assert page.has_selector?("#mark_as_sent_#{fulfillment_file.id}") if fulfillment_file.status == 'in_process'
        assert page.has_selector?("#download_xls_#{fulfillment_file.id}")
        click_link_or_button 'View'
      end

      # See "export all to xls" button at fulfillment file
      within('#report_results') { assert page.has_selector?('#export_all_to_xls_btn') }

      fulfillments.each do |fulfillment|
        fulfillment.reload
        assert_equal fulfillment.status, 'in_process'
      end

      assert_equal fulfillments.count, fulfillment_file.fulfillments.count
    end
  end

  def active_merchant_stub
    active_merchant_stubs_payeezy('100', 'Transaction Normal - Approved with Stub', true)
  end

  test "Create file at 'all time' checkbox" do
    setup_user

    5.times { FactoryBot.create(:fulfillment, user_id: @saved_user.id, product_sku: @product.sku, product_id: @product.id, club_id: @club.id) }
    fulfillments = []
    fulfillments << @saved_user.fulfillments.first
    fulfillments << @saved_user.fulfillments.last

    generate_fulfillment_files(true, fulfillments)
    @saved_user.fulfillments
  end

  test 'Create file at Date range' do
    setup_user

    5.times { FactoryBot.create(:fulfillment, user_id: @saved_user.id, product_sku: @product.sku, product_id: @product.id, club_id: @club.id) }
    fulfillments = []
    fulfillments << @saved_user.fulfillments.first
    fulfillments << @saved_user.fulfillments.last

    generate_fulfillment_files(false, fulfillments)
  end

  test 'Create a fulfillment file with all times and with sloop product' do
    setup_user
    fulfillments = []
    fulfillments << @saved_user.fulfillments.first
    5.times { FactoryBot.create(:fulfillment, user_id: @saved_user.id, product_sku: @product.sku, product_id: @product.id, club_id: @club.id) }

    generate_fulfillment_files(true, fulfillments, nil, nil, nil)
  end

  test 'Create a fulfillment file with initial-end dates and with sloop product' do
    setup_user

    5.times { FactoryBot.create(:fulfillment, user_id: @saved_user.id, product_sku: @product.sku, product_id: @product.id, club_id: @club.id) }
    @saved_user.fulfillments
    fulfillments = []
    fulfillments << @saved_user.fulfillments.first
    generate_fulfillment_files(false, fulfillments, nil, nil, 'not_processed', false)

    fulfillments = []
    fulfillments << @saved_user.fulfillments[1]
    fulfillments << @saved_user.fulfillments[2]
    generate_fulfillment_files(false, fulfillments, nil, nil, 'not_processed', false)

    fulfillments = []
    fulfillments << @saved_user.fulfillments[3]
    fulfillments << @saved_user.fulfillments[4]
    generate_fulfillment_files(false, fulfillments, nil, nil, 'not_processed', false)

    visit list_fulfillment_files_path(partner_prefix: @partner.prefix, club_prefix: @club.name)

    fulfillment_files = FulfillmentFile.all
    assert_equal fulfillment_files.count, 3

    within('#fulfillment_files_table') do
      fulfillment_files.each do |fulfillment_file|
        assert page.has_content?(fulfillment_file.id.to_s)
        assert page.has_content?(fulfillment_file.status)
        assert page.has_content?(fulfillment_file.product)
        assert page.has_content?(fulfillment_file.dates)
        assert page.has_content?(fulfillment_file.fulfillments_processed)
      end
    end
  end

  test 'Mark fulfillment file at sent status' do
    setup_user

    5.times { FactoryBot.create(:fulfillment, user_id: @saved_user.id, product_sku: @product.sku, product_id: @product.id, club_id: @club.id) }
    generate_fulfillment_files(false, @saved_user.fulfillments, nil, nil, 'not_processed', false)
    visit list_fulfillment_files_path(partner_prefix: @partner.prefix, club_prefix: @club.name)
    within('#fulfillment_files_table') do
      click_link_or_button 'Mark as Sent'
      confirm_ok_js
    end
    assert page.has_content?('Fulfillment file marked as sent successfully')

    within('#fulfillment_files_table') do
      assert page.has_content?('sent')
      assert page.has_no_selector?('#mark_as_sent')
    end

    file = FulfillmentFile.last
    assert_equal file.status, 'sent'
  end

  test 'Mark fulfillment file at packed status' do
    setup_user

    5.times { FactoryBot.create(:fulfillment, user_id: @saved_user.id, product_sku: @product.sku, product_id: @product.id, club_id: @club.id) }
    generate_fulfillment_files(false, @saved_user.fulfillments, nil, nil, 'not_processed', false)
    visit list_fulfillment_files_path(partner_prefix: @partner.prefix, club_prefix: @club.name)
    within('#fulfillment_files_table') do
      click_link_or_button 'Mark as Packed'
      confirm_ok_js
    end
    assert page.has_content?('Fulfillment file marked as packed successfully')

    fulfillment_file = FulfillmentFile.last

    within('#fulfillment_files_table') do
      assert page.has_content?('packed')
      assert page.has_no_selector?("#mark_as_packed_#{fulfillment_file.id}")
      assert page.has_selector?("#mark_as_sent_#{fulfillment_file.id}")
    end

    file = FulfillmentFile.last
    assert_equal file.status, 'packed'
  end

  # fulfillment_managment role - Fulfillment File page
  test 'Fulfillments file page should filter the results by Club' do
    setup_user
    @club2 = FactoryBot.create(:simple_club_with_gateway)

    FactoryBot.create(:fulfillment_file, agent_id: @admin_agent.id, club_id: @club.id, created_at: Time.zone.now - 2.days)
    FactoryBot.create(:fulfillment_file, agent_id: @admin_agent.id, club_id: @club.id, created_at: Time.zone.now - 1.days)
    FactoryBot.create(:fulfillment_file, agent_id: @admin_agent.id, club_id: @club2.id, created_at: Time.zone.now + 1.days)
    FactoryBot.create(:fulfillment_file, agent_id: @admin_agent.id, club_id: @club2.id, created_at: Time.zone.now + 2.days)

    visit list_fulfillment_files_path(partner_prefix: @partner.prefix, club_prefix: @club.name)
    fulfillment_file = FulfillmentFile.where(club_id: @club.id)
    fulfillment_file2 = FulfillmentFile.where(club_id: @club2.id)
    within('#fulfillment_files_table') do
      assert page.has_content?(I18n.l(fulfillment_file.first.created_at.to_date))
      assert page.has_content?(I18n.l(fulfillment_file.last.created_at.to_date))
      assert page.has_no_content?(I18n.l(fulfillment_file2.first.created_at.to_date))
      assert page.has_no_content?(I18n.l(fulfillment_file2.last.created_at.to_date))

      first(:link, 'Mark as Sent').click
      confirm_ok_js
    end
    assert page.has_content?('Fulfillment file marked as sent successfully.')

    within('#fulfillment_files_table') { first(:link, 'View').click }

    assert page.has_content?('Fulfillments for file')
  end
end
