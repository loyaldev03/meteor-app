require 'test_helper'

class FulfillmentTest < ActiveSupport::TestCase
  
  setup do 
    @club = FactoryBot.create(:simple_club_with_gateway)
    @terms_of_membership_with_gateway = FactoryBot.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    @terms_of_membership_with_gateway_yearly = FactoryBot.create(:terms_of_membership_with_gateway_yearly, :club_id => @club.id)
  end

  def setup_products 
    @product_with_stock = FactoryBot.create(:product, club_id: @terms_of_membership_with_gateway.club.id, sku: 'PRODUCT' )
    @product_without_stock = FactoryBot.create(:product_without_stock_and_not_recurrent, club_id: @terms_of_membership_with_gateway.club.id, sku: 'NOSTOCK')
    @product_recurrent = FactoryBot.create(:product_with_recurrent, club_id: @terms_of_membership_with_gateway.club.id, sku: 'NORECURRENT')
  end

  def enroll_user(user,tom, amount=23, cc_blank=false, cc_card = nil)
    active_merchant_stubs_payeezy("100", "Transaction Normal - Approved with Stub", true, @credit_card.number)
    credit_card = cc_card.nil? ? @credit_card : cc_card
    answer = User.enroll(tom, @current_agent, amount, 
      { first_name: user.first_name,
        last_name: user.last_name, address: user.address, city: user.city, gender: 'M',
        zip: user.zip, state: user.state, email: user.email, type_of_phone_number: user.type_of_phone_number,
        phone_country_code: user.phone_country_code, phone_area_code: user.phone_area_code,
        phone_local_number: user.phone_local_number, country: 'US', 
        product_sku: Settings.others_product }, 
      { number: credit_card.number, 
        expire_year: credit_card.expire_year, expire_month: credit_card.expire_month },
      cc_blank)

    assert (answer[:code] == Settings.error_codes.success), answer[:message]+answer.inspect

    saved_user = User.find(answer[:member_id])
    assert_not_nil saved_user
    assert_equal saved_user.status, 'provisional'
    saved_user
  end
 
  #cancel user and check if not_processed fulfillments were updated to canceled
  test "cancel user after more than two days of enrollment. It should not cancel the fulfillment." do
    setup_products
    user = FactoryBot.build(:user)
    @credit_card = FactoryBot.build(:credit_card)
    user = enroll_user(user, @terms_of_membership_with_gateway)
    fulfillment = user.fulfillments.first
    assert_equal fulfillment.status, "not_processed"

    cancel_date = user.join_date + Settings.days_to_wait_to_cancel_fulfillments.days
    user.cancel! cancel_date, "canceling"
    Timecop.travel(cancel_date) do
      TasksHelpers.cancel_all_member_up_today
      user.reload
      assert_equal user.status, "lapsed"
      assert_equal fulfillment.status, "not_processed"
    end
  end

  test "cancel user before two days of enrollment. It should cancel the fulfillment." do
    setup_products
    user = FactoryBot.build(:user)
    @credit_card = FactoryBot.build(:credit_card)
    user = enroll_user(user, @terms_of_membership_with_gateway)
    fulfillment = user.fulfillments.first
    assert_equal fulfillment.status, "not_processed"

    cancel_date = user.join_date + 1.day
    user.cancel! cancel_date, "canceling"
    Timecop.travel(cancel_date) do
      TasksHelpers.cancel_all_member_up_today
      user.reload
      fulfillment.reload
      assert_equal user.status, "lapsed"
      assert_equal fulfillment.status, "canceled"
    end
  end

  test "Canceling fulfillment should replenish stock" do
    setup_products
    user = FactoryBot.build(:user)
    @credit_card = FactoryBot.build(:credit_card)
    user = enroll_user(user, @terms_of_membership_with_gateway)
    fulfillment = user.fulfillments.first
    assert_equal fulfillment.status, "not_processed"

    prev_stock = fulfillment.product.stock
    cancel_date = user.join_date + 1.day
    user.cancel! cancel_date, "canceling"
    Timecop.travel(cancel_date) do
      TasksHelpers.cancel_all_member_up_today
      user.reload
      fulfillment.reload
      assert_equal user.status, "lapsed"
      assert_equal fulfillment.status, "canceled"
      assert_equal fulfillment.product.reload.stock, prev_stock+1
    end
  end

  # Fulfillment should set as manual_review_required with match age correctly calcultaed.
  test "Fulfillment should set as manual_review_required when - when there are full_name_match" do 
    setup_products
    @credit_card = FactoryBot.build(:credit_card)
    user = FactoryBot.build(:user)
    dup_user = FactoryBot.build(:user, first_name: user.first_name, last_name: user.last_name, state: user.state)
    user = enroll_user(user, @terms_of_membership_with_gateway, nil, true)

    wait_for_first_fulfillment = 4
    wait_for_second_fulfillment = 8

    Timecop.travel(Time.zone.now + wait_for_first_fulfillment.days) do 
      user_dup = enroll_user(dup_user, @terms_of_membership_with_gateway, nil, true)
      assert_not_nil Operation.find_by(user_id: user_dup.id, operation_type: Settings.operation_types.fulfillment_created_as_manual_review_required)
      
      fulfillment = user.fulfillments.last
      fulfillment_dup = user_dup.fulfillments.last

      assert_equal fulfillment.status, 'not_processed' 
      assert_equal fulfillment_dup.status, 'manual_review_required'
      assert_equal fulfillment_dup.full_name_matches_count, 1
      assert_equal fulfillment_dup.average_match_age, wait_for_first_fulfillment
      assert_equal fulfillment_dup.suspected_fulfillment_evidences.last.full_name_match, true 
      assert_equal fulfillment_dup.suspected_fulfillment_evidences.last.match_age, wait_for_first_fulfillment
    end

    Timecop.travel(Time.zone.now + wait_for_second_fulfillment.days) do
      another_dup_user = FactoryBot.build(:user, first_name: user.first_name, last_name: user.last_name, state: user.state)
      another_dup_user = enroll_user(another_dup_user, @terms_of_membership_with_gateway, nil, true)
      assert_not_nil Operation.find_by(user_id: another_dup_user.id, operation_type: Settings.operation_types.fulfillment_created_as_manual_review_required)

      fulfillment_dup = another_dup_user.fulfillments.last
      assert_equal fulfillment_dup.status, 'manual_review_required'
      assert_equal fulfillment_dup.full_name_matches_count, 2
      assert_equal fulfillment_dup.average_match_age, (wait_for_first_fulfillment+wait_for_second_fulfillment)/2
      assert_equal fulfillment_dup.suspected_fulfillment_evidences.last.full_name_match, true
      assert_equal fulfillment_dup.suspected_fulfillment_evidences.first.match_age, wait_for_second_fulfillment
      assert_equal fulfillment_dup.suspected_fulfillment_evidences.last.match_age, wait_for_first_fulfillment
    end
  end

  test "Fulfillment should set as manual_review_required - when there are full_phone_number_match" do 
    setup_products
    @credit_card = FactoryBot.build(:credit_card)
    user = FactoryBot.build(:user)
    dup_user = FactoryBot.build(:user, phone_country_code: user.phone_country_code, phone_area_code: user.phone_area_code, phone_local_number: user.phone_local_number)
    user = enroll_user(user, @terms_of_membership_with_gateway, nil, true)
    user_dup = enroll_user(dup_user, @terms_of_membership_with_gateway, nil, true)

    fulfillment = user.fulfillments.last
    fulfillment_dup = user_dup.fulfillments.last
  
    assert_equal fulfillment.status, 'not_processed' 
    assert_equal fulfillment_dup.status, 'manual_review_required'
    assert_equal fulfillment_dup.suspected_fulfillment_evidences.last.full_phone_number_match, true 
    assert_equal fulfillment_dup.full_phone_number_matches_count, 1 

    another_dup_user = FactoryBot.build(:user, phone_country_code: user.phone_country_code, phone_area_code: user.phone_area_code, phone_local_number: user.phone_local_number)
    another_dup_user = enroll_user(another_dup_user, @terms_of_membership_with_gateway, nil, true)
    fulfillment_dup = another_dup_user.fulfillments.last
    assert_equal fulfillment_dup.status, 'manual_review_required'
    assert_equal fulfillment_dup.suspected_fulfillment_evidences.last.full_phone_number_match, true 
    assert_equal fulfillment_dup.full_phone_number_matches_count, 2
  end

  test "Fulfillment should set as manual_review_required - when there are full_address_match" do 
    setup_products
    @credit_card = FactoryBot.build(:credit_card)
    user = FactoryBot.build(:user)
    dup_user = FactoryBot.build(:user, address: user.address, city: user.city, zip: user.zip)
    user = enroll_user(user, @terms_of_membership_with_gateway, nil, true)
    user_dup = enroll_user(dup_user, @terms_of_membership_with_gateway, nil, true)

    fulfillment = user.fulfillments.last
    fulfillment_dup = user_dup.fulfillments.last
  
    assert_equal fulfillment.status, 'not_processed' 
    assert_equal fulfillment_dup.status, 'manual_review_required'
    assert_equal fulfillment_dup.suspected_fulfillment_evidences.last.full_address_match, true 
    assert_equal fulfillment_dup.full_address_matches_count, 1 
  
    another_dup_user = FactoryBot.build(:user, address: user.address, city: user.city, zip: user.zip)
    another_dup_user = enroll_user(another_dup_user, @terms_of_membership_with_gateway, nil, true)

    fulfillment_dup = another_dup_user.fulfillments.last
    assert_equal fulfillment_dup.status, 'manual_review_required'
    assert_equal fulfillment_dup.suspected_fulfillment_evidences.last.full_address_match, true
    assert_equal fulfillment_dup.full_address_matches_count, 2
  end

  test "Fulfillment should set as manual_review_required - when multiple matches" do 
    setup_products
    @credit_card = FactoryBot.build(:credit_card)
    user = FactoryBot.build(:user)
    dup_user = FactoryBot.build(:user, address: user.address, city: user.city, zip: user.zip, phone_country_code: user.phone_country_code, phone_area_code: user.phone_area_code, phone_local_number: user.phone_local_number)
    user = enroll_user(user, @terms_of_membership_with_gateway, nil, true)
    user_dup = enroll_user(dup_user, @terms_of_membership_with_gateway, nil, true)

    fulfillment = user.fulfillments.last
    fulfillment_dup = user_dup.fulfillments.last
  
    assert_equal fulfillment.status, 'not_processed' 
    assert_equal fulfillment_dup.status, 'manual_review_required'
    assert_equal fulfillment_dup.suspected_fulfillment_evidences.last.full_phone_number_match, true 
    assert_equal fulfillment_dup.full_phone_number_matches_count, 1
    assert_equal fulfillment_dup.full_address_matches_count, 1

    another_dup_user = FactoryBot.build(:user, first_name: user.first_name, last_name: user.last_name, state: user.state, phone_country_code: user.phone_country_code, phone_area_code: user.phone_area_code, phone_local_number: user.phone_local_number)
    another_dup_user = enroll_user(another_dup_user, @terms_of_membership_with_gateway, nil, true)
    fulfillment_dup = another_dup_user.fulfillments.last
    assert_equal fulfillment_dup.status, 'manual_review_required'
    assert_equal fulfillment_dup.suspected_fulfillment_evidences.last.full_phone_number_match, true 
    assert_equal fulfillment_dup.full_phone_number_matches_count, 2
    assert_equal fulfillment_dup.full_name_matches_count, 1
  end

  test "Fulfillment should set as manual_review_required - when the users recovers" do 
    setup_products
    @credit_card = FactoryBot.build(:credit_card)
    user = FactoryBot.build(:user)
    user = enroll_user(user, @terms_of_membership_with_gateway, nil, true)

    user.set_as_canceled
    user.recover(@terms_of_membership_with_gateway, nil, { product_sku: @product_with_stock.sku })

    fulfillment = user.fulfillments.last
    assert_equal user.fulfillments.first.status, 'canceled'    
    assert_equal fulfillment.status, 'manual_review_required'
    assert_equal fulfillment.suspected_fulfillment_evidences.last.email_match, true 
    assert_equal fulfillment.email_matches_count, 1
  end

  test "Fulfillment should set as canceled when user is testing account" do
    setup_products
    @credit_card = FactoryBot.build(:credit_card)
    ['admin@xagax.com', 'admin@stoneacreinc.com'].each do |email|
      user = FactoryBot.build(:user, email: email)
      user = enroll_user(user, @terms_of_membership_with_gateway, nil, true)
      fulfillment = user.fulfillments.last
      assert user.testing_account?
      assert_equal fulfillment.status, 'canceled'
    end
    user = FactoryBot.build(:user, first_name: 'test')
    user = enroll_user(user, @terms_of_membership_with_gateway, nil, true)
    fulfillment = user.fulfillments.last
    assert user.testing_account?
    assert_equal fulfillment.status, 'canceled'

    user = FactoryBot.build(:user, last_name: 'test')
    user = enroll_user(user, @terms_of_membership_with_gateway, nil, true)
    fulfillment = user.fulfillments.last
    assert user.testing_account?
    assert_equal fulfillment.status, 'canceled'
  end

  #############STORE TEST CASES ######################

  def setup_store_integration
    SacStore.enable_integration! 
    @club1 = FactoryBot.create(:simple_club_with_gateway)      
    @transport_settings = FactoryBot.create(:transport_settings_store, club_id:@club1.id)    
    @terms_of_membership_with_gateway1 = FactoryBot.create(:terms_of_membership_with_gateway, :club_id => @club1.id)            
  end

  def stub_store_stock_movement_creation
  answer = Hashie::Mash.new({ status: 200, body: { code: 200, success: true, message: 'Stock Movement created successfully', current_stock: 9, stock_movement_id: 1738} })
  Faraday::Connection.any_instance.stubs(:post).returns(answer)
  end

  def stub_store_stock_movement_canceled
  answer = Hashie::Mash.new({ status: 200, body: { code: 200, success: true, message: 'Fulfillment cancelled successfully'} })
  Faraday::Connection.any_instance.stubs(:post).returns(answer)
  end

  test "Decrease stock after create a fulfillment at not_processed status" do  
    setup_store_integration
    user = FactoryBot.build(:user)
    @credit_card = FactoryBot.build(:credit_card)   
    stub_store_stock_movement_creation
    user = enroll_user(user, @terms_of_membership_with_gateway1)
    fulfillment = user.fulfillments.first
    assert_equal fulfillment.status, "not_processed"   
    fulfillment.reload
    product = Product.second
    assert_equal(product.stock, 9)
    assert_equal(fulfillment.store_id, 1738)
    assert_equal(fulfillment.sync_result, 'success')      
  end

  test "Increase stock after canceled a fulfillment" do    
    setup_store_integration
    user = FactoryBot.build(:user)
    @credit_card = FactoryBot.build(:credit_card)   
    stub_store_stock_movement_creation
    user = enroll_user(user, @terms_of_membership_with_gateway1)
    fulfillment = user.fulfillments.first
    stub_store_stock_movement_canceled
    fulfillment.update_status(nil, 'canceled')  
    product = Product.second
    assert_equal(product.stock, 10)
    assert_nil fulfillment.store_id   
    assert_equal(fulfillment.sync_result, 'success')   
  end  
end