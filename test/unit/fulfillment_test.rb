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

  test "active user can't renew fulfillments" do 
    [ 1, 5, 15, 25 ].each do |time|
      [ 1, 3 ].each do |recycled_times|
        user = create_active_user(@terms_of_membership_with_gateway, :active_user, :enrollment_info, { recycled_times: recycled_times }, { join_date: Time.zone.now-time.month })
        assert !user.can_renew_fulfillment?, "monthly recycled_times: #{recycled_times} and join_date: #{I18n.l(user.join_date, :format => :only_date)} and actual date #{I18n.l(Time.zone.now, :format => :only_date)}"
      end
    end

    [ 1, 5, 15, 25, 12 ].each do |time|
      [ 1, 3 ].each do |recycled_times|
        user = create_active_user(@terms_of_membership_with_gateway_yearly, :active_user, :enrollment_info, { recycled_times: recycled_times }, { join_date: Time.zone.now-time.year })
        assert !user.can_renew_fulfillment?, "yearly recycled_times: #{recycled_times} and join_date: #{I18n.l(user.join_date, :format => :only_date)} and actual date #{I18n.l(Time.zone.now, :format => :only_date)}"
      end
    end
  end

  test "active user can renew fulfillments" do 
    [ 12, 24, 36 ].each do |time|
      user = create_active_user(@terms_of_membership_with_gateway, :active_user, :enrollment_info, { recycled_times: 0 }, { join_date: Time.zone.now-time.month })
      assert user.can_renew_fulfillment?, "monthly with quota 12 paid"
    end
    [ 1, 2, 3, 4 ].each do |time|
      user = create_active_user(@terms_of_membership_with_gateway_yearly, :active_user, :enrollment_info, { recycled_times: 0 }, { join_date: Time.zone.now-time.year })
      assert user.can_renew_fulfillment?, "yearly with quota 24 paid"
    end
  end

  test "fulfillment not_processed renewal" do 
    user = create_active_user(@terms_of_membership_with_gateway)
    user.reload
    fulfillment = FactoryGirl.build(:fulfillment)
    fulfillment.user = user
    fulfillment.renewable_at = Time.zone.now - 3.days
    fulfillment.recurrent = true
    fulfillment.save
    assert_equal Fulfillment.to_be_renewed.count, 1
    assert_difference('Fulfillment.count') do  
      fulfillment.renew!
      assert_equal fulfillment.renewed, true
    end
    assert_no_difference('Fulfillment.count') do  
      fulfillment.renew!
    end
    assert_equal Fulfillment.to_be_renewed.count, 0
  end

  test "fulfillment processing cant be renewed" do 
    user = create_active_user(@terms_of_membership_with_gateway)
    user.reload
    fulfillment = FactoryGirl.build(:fulfillment)
    fulfillment.user = user
    fulfillment.renewable_at = Time.zone.now - 3.days
    fulfillment.recurrent = true
    fulfillment.save
    fulfillment.set_as_in_process
    assert_equal Fulfillment.to_be_renewed.count, 0
  end

  test "fulfillment sent renewal" do 
    user = create_active_user(@terms_of_membership_with_gateway)
    user.reload
    fulfillment = FactoryGirl.build(:fulfillment)
    fulfillment.user = user
    fulfillment.renewable_at = Time.zone.now - 3.days
    fulfillment.recurrent = true
    fulfillment.save
    fulfillment.set_as_in_process
    fulfillment.set_as_sent
    assert_equal Fulfillment.to_be_renewed.count, 1
    assert_difference('Fulfillment.count') do  
      fulfillment.renew!
      assert_equal fulfillment.renewed, true
    end
    assert_no_difference('Fulfillment.count') do  
      fulfillment.renew!
    end
    assert_equal Fulfillment.to_be_renewed.count, 0
  end

  test "Should send fulfillments on acepted applied user" do
    user = create_active_user(@terms_of_membership_with_gateway, :applied_user)
    assert_difference('Fulfillment.count') do
      user.set_as_provisional!
    end
  end

  test "Should send fulfillments on acepted applied user and set correct status on fulfillments" do
    setup_products
    user = create_active_user(@terms_of_membership_with_gateway, :applied_user, :enrollment_info_with_product_recurrent)
    assert_difference('Fulfillment.count') do
      user.set_as_provisional!
    end
    ff = user.fulfillments.first
    assert_equal ff.status, 'not_processed'
  end

  test "Should create new fulfillment with recurrent and renewable_date" do
    setup_products
    user = create_active_user(@terms_of_membership_with_gateway, :applied_user, :enrollment_info_with_product_recurrent)
    assert_difference('Fulfillment.count') do
      user.set_as_provisional!
    end

    fulfillment_out_of_stock = user.fulfillments.first
    assert_equal fulfillment_out_of_stock.recurrent, true, "Recurrent on fulfillment is not recurrent when it should be."
    assert_equal fulfillment_out_of_stock.renewable_at, fulfillment_out_of_stock.assigned_at + 1.year, "Renewable date was not set properly."
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
