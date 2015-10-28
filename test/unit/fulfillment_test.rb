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

  def enroll_user(tom, amount=23, cc_blank=false, cc_card = nil)
    credit_card = cc_card.nil? ? @credit_card : cc_card
    answer = User.enroll(tom, @current_agent, amount, 
      { first_name: @user.first_name,
        last_name: @user.last_name, address: @user.address, city: @user.city, gender: 'M',
        zip: @user.zip, state: @user.state, email: @user.email, type_of_phone_number: @user.type_of_phone_number,
        phone_country_code: @user.phone_country_code, phone_area_code: @user.phone_area_code,
        type_of_phone_number: 'Home', phone_local_number: @user.phone_local_number, country: 'US', 
        product_sku: Settings.kit_card_product }, 
      { number: credit_card.number, 
        expire_year: credit_card.expire_year, expire_month: credit_card.expire_month },
      cc_blank)

    assert (answer[:code] == Settings.error_codes.success), answer[:message]+answer.inspect

    user = User.find(answer[:member_id])
    assert_not_nil user
    assert_equal user.status, 'provisional'
    user
  end
 
  # cancel user and check if not_processed fulfillments were updated to canceled
  test "cancel user after more than two days of enrollment. It should not cancel the fulfillment." do
    setup_products
    @user = FactoryGirl.build(:user)
    @credit_card = FactoryGirl.build(:credit_card)
    user = enroll_user(@terms_of_membership_with_gateway)
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
    @user = FactoryGirl.build(:user)
    @credit_card = FactoryGirl.build(:credit_card)
    user = enroll_user(@terms_of_membership_with_gateway)
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
    @user = FactoryGirl.build(:user)
    @credit_card = FactoryGirl.build(:credit_card)
    user = enroll_user(@terms_of_membership_with_gateway)
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
end
