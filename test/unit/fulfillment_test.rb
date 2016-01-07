require 'test_helper'

class FulfillmentTest < ActiveSupport::TestCase
  
  setup do 
    @club = FactoryGirl.create(:simple_club_with_gateway)
    @terms_of_membership_with_gateway = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    @terms_of_membership_with_gateway_yearly = FactoryGirl.create(:terms_of_membership_with_gateway_yearly, :club_id => @club.id)
  end

  def setup_products 
    @product_with_stock = FactoryGirl.create(:product, club_id: @terms_of_membership_with_gateway.club.id)
    @product_without_stock = FactoryGirl.create(:product_without_stock_and_not_recurrent, club_id: @terms_of_membership_with_gateway.club.id)
    @product_recurrent = FactoryGirl.create(:product_with_recurrent, club_id: @terms_of_membership_with_gateway.club.id)
  end

  def enroll_user(user,tom, amount=23, cc_blank=false, cc_card = nil)
    credit_card = cc_card.nil? ? @credit_card : cc_card
    answer = User.enroll(tom, @current_agent, amount, 
      { first_name: user.first_name,
        last_name: user.last_name, address: user.address, city: user.city, gender: 'M',
        zip: user.zip, state: user.state, email: user.email, type_of_phone_number: user.type_of_phone_number,
        phone_country_code: user.phone_country_code, phone_area_code: user.phone_area_code,
        phone_local_number: user.phone_local_number, country: 'US', 
        product_sku: Settings.kit_card_product }, 
      { number: credit_card.number, 
        expire_year: credit_card.expire_year, expire_month: credit_card.expire_month },
      cc_blank)

    assert (answer[:code] == Settings.error_codes.success), answer[:message]+answer.inspect

    saved_user = User.find(answer[:member_id])
    assert_not_nil saved_user
    assert_equal saved_user.status, 'provisional'
    saved_user
  end
 
  # cancel user and check if not_processed fulfillments were updated to canceled
  test "cancel user after more than two days of enrollment. It should not cancel the fulfillment." do
    setup_products
    user = FactoryGirl.build(:user)
    @credit_card = FactoryGirl.build(:credit_card)
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
    user = FactoryGirl.build(:user)
    @credit_card = FactoryGirl.build(:credit_card)
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
    user = FactoryGirl.build(:user)
    @credit_card = FactoryGirl.build(:credit_card)
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
    @credit_card = FactoryGirl.build(:credit_card)
    user = FactoryGirl.build(:user)
    dup_user = FactoryGirl.build(:user, first_name: user.first_name, last_name: user.last_name, state: user.state)
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
      another_dup_user = FactoryGirl.build(:user, first_name: user.first_name, last_name: user.last_name, state: user.state)
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
    @credit_card = FactoryGirl.build(:credit_card)
    user = FactoryGirl.build(:user)
    dup_user = FactoryGirl.build(:user, phone_country_code: user.phone_country_code, phone_area_code: user.phone_area_code, phone_local_number: user.phone_local_number)
    user = enroll_user(user, @terms_of_membership_with_gateway, nil, true)
    user_dup = enroll_user(dup_user, @terms_of_membership_with_gateway, nil, true)

    fulfillment = user.fulfillments.last
    fulfillment_dup = user_dup.fulfillments.last
  
    assert_equal fulfillment.status, 'not_processed' 
    assert_equal fulfillment_dup.status, 'manual_review_required'
    assert_equal fulfillment_dup.suspected_fulfillment_evidences.last.full_phone_number_match, true 
    assert_equal fulfillment_dup.full_phone_number_matches_count, 1 

    another_dup_user = FactoryGirl.build(:user, phone_country_code: user.phone_country_code, phone_area_code: user.phone_area_code, phone_local_number: user.phone_local_number)
    another_dup_user = enroll_user(another_dup_user, @terms_of_membership_with_gateway, nil, true)
    fulfillment_dup = another_dup_user.fulfillments.last
    assert_equal fulfillment_dup.status, 'manual_review_required'
    assert_equal fulfillment_dup.suspected_fulfillment_evidences.last.full_phone_number_match, true 
    assert_equal fulfillment_dup.full_phone_number_matches_count, 2
  end

  test "Fulfillment should set as manual_review_required - when there are full_address_match" do 
    setup_products
    @credit_card = FactoryGirl.build(:credit_card)
    user = FactoryGirl.build(:user)
    dup_user = FactoryGirl.build(:user, address: user.address, city: user.city, zip: user.zip)
    user = enroll_user(user, @terms_of_membership_with_gateway, nil, true)
    user_dup = enroll_user(dup_user, @terms_of_membership_with_gateway, nil, true)

    fulfillment = user.fulfillments.last
    fulfillment_dup = user_dup.fulfillments.last
  
    assert_equal fulfillment.status, 'not_processed' 
    assert_equal fulfillment_dup.status, 'manual_review_required'
    assert_equal fulfillment_dup.suspected_fulfillment_evidences.last.full_address_match, true 
    assert_equal fulfillment_dup.full_address_matches_count, 1 
  
    another_dup_user = FactoryGirl.build(:user, address: user.address, city: user.city, zip: user.zip)
    another_dup_user = enroll_user(another_dup_user, @terms_of_membership_with_gateway, nil, true)

    fulfillment_dup = another_dup_user.fulfillments.last
    assert_equal fulfillment_dup.status, 'manual_review_required'
    assert_equal fulfillment_dup.suspected_fulfillment_evidences.last.full_address_match, true
    assert_equal fulfillment_dup.full_address_matches_count, 2
  end

  test "Fulfillment should set as manual_review_required - when multiple matches" do 
    setup_products
    @credit_card = FactoryGirl.build(:credit_card)
    user = FactoryGirl.build(:user)
    dup_user = FactoryGirl.build(:user, address: user.address, city: user.city, zip: user.zip, phone_country_code: user.phone_country_code, phone_area_code: user.phone_area_code, phone_local_number: user.phone_local_number)
    user = enroll_user(user, @terms_of_membership_with_gateway, nil, true)
    user_dup = enroll_user(dup_user, @terms_of_membership_with_gateway, nil, true)

    fulfillment = user.fulfillments.last
    fulfillment_dup = user_dup.fulfillments.last
  
    assert_equal fulfillment.status, 'not_processed' 
    assert_equal fulfillment_dup.status, 'manual_review_required'
    assert_equal fulfillment_dup.suspected_fulfillment_evidences.last.full_phone_number_match, true 
    assert_equal fulfillment_dup.full_phone_number_matches_count, 1
    assert_equal fulfillment_dup.full_address_matches_count, 1

    another_dup_user = FactoryGirl.build(:user, first_name: user.first_name, last_name: user.last_name, state: user.state, phone_country_code: user.phone_country_code, phone_area_code: user.phone_area_code, phone_local_number: user.phone_local_number)
    another_dup_user = enroll_user(another_dup_user, @terms_of_membership_with_gateway, nil, true)
    fulfillment_dup = another_dup_user.fulfillments.last
    assert_equal fulfillment_dup.status, 'manual_review_required'
    assert_equal fulfillment_dup.suspected_fulfillment_evidences.last.full_phone_number_match, true 
    assert_equal fulfillment_dup.full_phone_number_matches_count, 2
    assert_equal fulfillment_dup.full_name_matches_count, 1
  end

  test "Fulfillment should set as manual_review_required - when the users recovers" do 
    setup_products
    @credit_card = FactoryGirl.build(:credit_card)
    user = FactoryGirl.build(:user)
    user = enroll_user(user, @terms_of_membership_with_gateway, nil, true)

    user.set_as_canceled
    user.recover(@terms_of_membership_with_gateway, nil, { product_sku: @product_with_stock.sku })

    fulfillment = user.fulfillments.last
    assert_equal user.fulfillments.first.status, 'canceled'    
    assert_equal fulfillment.status, 'manual_review_required'
    assert_equal fulfillment.suspected_fulfillment_evidences.last.email_match, true 
    assert_equal fulfillment.email_matches_count, 1
  end
end