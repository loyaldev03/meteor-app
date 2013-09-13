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

  test "active member can't renew fulfillments" do 
    [ 1, 5, 15, 25 ].each do |time|
      [ 1, 3 ].each do |recycled_times|
        member = create_active_member(@terms_of_membership_with_gateway, :active_member, :enrollment_info, { recycled_times: recycled_times }, { join_date: Time.zone.now-time.month })
        assert !member.can_renew_fulfillment?, "monthly recycled_times: #{recycled_times} and join_date: #{I18n.l(member.join_date, :format => :only_date)} and actual date #{I18n.l(Time.zone.now, :format => :only_date)}"
      end
    end

    [ 1, 5, 15, 25, 12 ].each do |time|
      [ 1, 3 ].each do |recycled_times|
        member = create_active_member(@terms_of_membership_with_gateway_yearly, :active_member, :enrollment_info, { recycled_times: recycled_times }, { join_date: Time.zone.now-time.year })
        assert !member.can_renew_fulfillment?, "yearly recycled_times: #{recycled_times} and join_date: #{I18n.l(member.join_date, :format => :only_date)} and actual date #{I18n.l(Time.zone.now, :format => :only_date)}"
      end
    end
  end

  test "active member can renew fulfillments" do 
    [ 12, 24, 36 ].each do |time|
      member = create_active_member(@terms_of_membership_with_gateway, :active_member, :enrollment_info, { recycled_times: 0 }, { join_date: Time.zone.now-time.month })
      assert member.can_renew_fulfillment?, "monthly with quota 12 paid"
    end
    [ 1, 2, 3, 4 ].each do |time|
      member = create_active_member(@terms_of_membership_with_gateway_yearly, :active_member, :enrollment_info, { recycled_times: 0 }, { join_date: Time.zone.now-time.year })
      assert member.can_renew_fulfillment?, "yearly with quota 24 paid"
    end
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
