require 'test_helper'

class Users::PostEnrollmentTasksJobTest < ActiveSupport::TestCase
  setup do
    @club                                     = FactoryBot.create(:simple_club_with_gateway)
    @terms_of_membership_with_gateway         = FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club.id)
    @terms_of_membership_with_gateway_yearly  = FactoryBot.create(:terms_of_membership_with_gateway_yearly, club_id: @club.id)
    @product_with_stock                       = FactoryBot.create(:product, club_id: @terms_of_membership_with_gateway.club.id, sku: 'PRODUCT')
    @product_without_stock                    = FactoryBot.create(:product_without_stock_and_not_recurrent, club_id: @terms_of_membership_with_gateway.club.id, sku: 'NOSTOCK')
    @product_recurrent                        = FactoryBot.create(:product_with_recurrent, club_id: @terms_of_membership_with_gateway.club.id, sku: 'NORECURRENT')
  end

  # Fulfillment should set as manual_review_required with match age correctly calcultaed.
  test 'Fulfillment should set as manual_review_required when - there are full_name_match' do
    @credit_card = FactoryBot.build(:credit_card)
    user = FactoryBot.build(:user)
    dup_user = FactoryBot.build(:user, first_name: user.first_name, last_name: user.last_name, state: user.state)
    user = enroll_user(user, @terms_of_membership_with_gateway, nil, true)

    wait_for_first_fulfillment = 4
    wait_for_second_fulfillment = 8

    Timecop.travel(Time.zone.now + wait_for_first_fulfillment.days) do
      user_dup = enroll_user(dup_user, @terms_of_membership_with_gateway, nil, true)
      assert_not_nil Operation.find_by(user_id: user_dup.id, operation_type: Settings.operation_types.fulfillment_created_as_manual_review_required)
      fulfillment     = user.fulfillments.last
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
      assert_equal fulfillment_dup.average_match_age, (wait_for_first_fulfillment + wait_for_second_fulfillment) / 2
      assert_equal fulfillment_dup.suspected_fulfillment_evidences.last.full_name_match, true
      assert_equal fulfillment_dup.suspected_fulfillment_evidences.first.match_age, wait_for_second_fulfillment
      assert_equal fulfillment_dup.suspected_fulfillment_evidences.last.match_age, wait_for_first_fulfillment
    end
  end

  test 'Fulfillment should set as manual_review_required - when there are full_phone_number_match' do
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

  test 'Fulfillment should set as manual_review_required - when there are full_address_match' do
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

  test 'Fulfillment should set as manual_review_required - when multiple matches' do
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

  test 'Fulfillment should set as manual_review_required - when the users recovers' do
    @credit_card = FactoryBot.build(:credit_card)
    user = FactoryBot.build(:user)
    user = enroll_user(user, @terms_of_membership_with_gateway, nil, true)

    user.set_as_canceled
    user.recover(@terms_of_membership_with_gateway, nil, product_sku: @product_with_stock.sku)

    fulfillment = user.fulfillments.last
    assert_equal user.fulfillments.first.status, 'canceled'
    assert_equal fulfillment.status, 'manual_review_required'
    assert_equal fulfillment.suspected_fulfillment_evidences.last.email_match, true
    assert_equal fulfillment.email_matches_count, 1
  end

  test 'Fulfillment should set as canceled when user is testing account' do
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
end
