require 'test_helper'
require 'sac_store/store'

class SacStore::FulfillmentModelTest < ActiveSupport::TestCase
  def setup_store_integration
    SacStore.enable_integration!
    @club1 = FactoryBot.create(:simple_club_with_gateway)
    @transport_settings = FactoryBot.create(:transport_settings_store, club_id: @club1.id)
    @terms_of_membership_with_gateway1 = FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club1.id)
  end

  def stub_store_stock_movement_creation
    answer = Hashie::Mash.new({ status: 200, body: { code: 200, success: true, message: 'Stock Movement created successfully', current_stock: 9, stock_movement_id: 1738 } })
    Faraday::Connection.any_instance.stubs(:post).returns(answer)
  end

  def stub_store_stock_movement_canceled
    answer = Hashie::Mash.new({ status: 200, body: { code: 200, success: true, message: 'Fulfillment cancelled successfully' } })
    Faraday::Connection.any_instance.stubs(:post).returns(answer)
  end

  test 'Decrease stock after create a fulfillment at not_processed status' do
    setup_store_integration
    stub_store_stock_movement_creation
    user          = FactoryBot.build(:user)
    @credit_card  = FactoryBot.build(:credit_card)
    user          = enroll_user(user, @terms_of_membership_with_gateway1)
    fulfillment   = user.fulfillments.first
    assert_equal fulfillment.status, 'not_processed'
    fulfillment.reload
    product = fulfillment.reload.product
    assert_equal(product.stock, 9)
    assert_equal(fulfillment.store_id, 1738)
    assert_equal(fulfillment.sync_result, 'success')
  end

  test 'Increase stock after canceled a fulfillment' do
    setup_store_integration
    user          = FactoryBot.build(:user)
    @credit_card  = FactoryBot.build(:credit_card)

    stub_store_stock_movement_creation
    user          = enroll_user(user, @terms_of_membership_with_gateway1)
    fulfillment   = user.fulfillments.first

    stub_store_stock_movement_canceled
    fulfillment.update_status(nil, 'canceled')
    product = fulfillment.reload.product
    assert_equal(product.stock, 10)
    assert_nil fulfillment.store_id
    assert_equal(fulfillment.sync_result, 'success')
  end
end
