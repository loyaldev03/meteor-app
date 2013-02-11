require 'test_helper'

class FulfillmentTest < ActiveSupport::TestCase
  
  setup do 
    @terms_of_membership_with_gateway = FactoryGirl.create(:terms_of_membership_with_gateway)
    @terms_of_membership_with_gateway_yearly = FactoryGirl.create(:terms_of_membership_with_gateway_yearly)
  end

  def setup_products 
    @product_with_stock = FactoryGirl.create(:product, club_id: @terms_of_membership_with_gateway.club.id)
    @product_without_stock = FactoryGirl.create(:product_without_stock_and_not_recurrent, club_id: @terms_of_membership_with_gateway.club.id)
    @product_recurrent = FactoryGirl.create(:product_with_recurrent, club_id: @terms_of_membership_with_gateway.club.id)
  end

  test "active member can't renew fulfillments" do 
    [ 1, 5, 15, 25 ].each do |quota|
      [ 0, 3 ].each do |recycled_times|
        member = create_active_member(@terms_of_membership_with_gateway, :active_member, :enrollment_info, { recycled_times: recycled_times }, { quota: quota })
        assert !member.can_renew_fulfillment?, "monthly recycled_times: #{recycled_times} and quota: #{quota}"
      end
    end

    [ 1, 5, 15, 25, 12 ].each do |quota|
      [ 0, 3 ].each do |recycled_times|
        member = create_active_member(@terms_of_membership_with_gateway_yearly, :active_member, :enrollment_info, { recycled_times: recycled_times }, { quota: quota })
        assert !member.can_renew_fulfillment?, "yearly recycled_times: #{recycled_times} and quota: #{quota}"
      end
    end
  end

  test "active member can renew fulfillments" do 
    member = create_active_member(@terms_of_membership_with_gateway, :active_member, :enrollment_info, { recycled_times: 0 }, { quota: 12, join_date: Time.zone.now-1.year })
    assert member.can_renew_fulfillment?, "monthly with quota 12 paid"

    member = create_active_member(@terms_of_membership_with_gateway_yearly, :active_member, :enrollment_info, { recycled_times: 0 }, { quota: 24, join_date: Time.zone.now-1.year })
    assert member.can_renew_fulfillment?, "yearly with quota 24 paid"
  end

  test "fulfillment not_processed renewal" do 
    member = create_active_member(@terms_of_membership_with_gateway)
    member.reload
    fulfillment = FactoryGirl.build(:fulfillment)
    fulfillment.member = member
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
    member = create_active_member(@terms_of_membership_with_gateway)
    member.reload
    fulfillment = FactoryGirl.build(:fulfillment)
    fulfillment.member = member
    fulfillment.renewable_at = Time.zone.now - 3.days
    fulfillment.recurrent = true
    fulfillment.save
    fulfillment.set_as_in_process
    assert_equal Fulfillment.to_be_renewed.count, 0
  end


  test "fulfillment sent renewal" do 
    member = create_active_member(@terms_of_membership_with_gateway)
    member.reload
    fulfillment = FactoryGirl.build(:fulfillment)
    fulfillment.member = member
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

  test "Should send fulfillments on acepted applied member" do
    member = create_active_member(@terms_of_membership_with_gateway, :applied_member)
    assert_difference('Fulfillment.count') do
      member.set_as_provisional!
    end
  end

  test "Should send fulfillments on acepted applied member and set correct status on fulfillments" do
    setup_products
    member = create_active_member(@terms_of_membership_with_gateway, :applied_member, :enrollment_info_with_product_recurrent)
    assert_difference('Fulfillment.count') do
      member.set_as_provisional!
    end
    ff = member.fulfillments.first
    assert_equal ff.status, 'not_processed'
  end

  test "Should create new fulfillment with recurrent and renewable_date" do
    setup_products
    member = create_active_member(@terms_of_membership_with_gateway, :applied_member, :enrollment_info_with_product_recurrent)
    assert_difference('Fulfillment.count') do
      member.set_as_provisional!
    end

    fulfillment_out_of_stock = member.fulfillments.first
    assert_equal fulfillment_out_of_stock.recurrent, true, "Recurrent on fulfillment is not recurrent when it should be."
    assert_equal fulfillment_out_of_stock.renewable_at, fulfillment_out_of_stock.assigned_at + 1.year, "Renewable date was not set properly."
  end
end
