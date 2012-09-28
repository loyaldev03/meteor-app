require 'test_helper'

class FulfillmentTest < ActiveSupport::TestCase
  
  setup do 
    @terms_of_membership_with_gateway = FactoryGirl.create(:terms_of_membership_with_gateway)
  end

  def setup_products 
    @product_with_stock = FactoryGirl.create(:product, club_id: @terms_of_membership_with_gateway.club.id)
    @product_without_stock = FactoryGirl.create(:product_without_stock_and_not_recurrent, club_id: @terms_of_membership_with_gateway.club.id)
    @product_recurrent = FactoryGirl.create(:product_with_recurrent, club_id: @terms_of_membership_with_gateway.club.id)
  end

  test "active member can receive fulfillments" do 
    member = FactoryGirl.create(:active_member, terms_of_membership: @terms_of_membership_with_gateway, club: @terms_of_membership_with_gateway.club)
    assert member.can_receive_another_fulfillment?
  end

  test "fulfillment not_processed renewal" do 
    member = FactoryGirl.create(:active_member, terms_of_membership: @terms_of_membership_with_gateway, club: @terms_of_membership_with_gateway.club)
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
    member = FactoryGirl.create(:active_member, terms_of_membership: @terms_of_membership_with_gateway, club: @terms_of_membership_with_gateway.club)
    member.reload
    fulfillment = FactoryGirl.build(:fulfillment)
    fulfillment.member = member
    fulfillment.renewable_at = Time.zone.now - 3.days
    fulfillment.recurrent = true
    fulfillment.save
    fulfillment.set_as_processing!
    assert_equal Fulfillment.to_be_renewed.count, 0
  end


  test "fulfillment sent renewal" do 
    member = FactoryGirl.create(:active_member, terms_of_membership: @terms_of_membership_with_gateway, club: @terms_of_membership_with_gateway.club)
    member.reload
    fulfillment = FactoryGirl.build(:fulfillment)
    fulfillment.member = member
    fulfillment.renewable_at = Time.zone.now - 3.days
    fulfillment.recurrent = true
    fulfillment.save
    fulfillment.set_as_processing!
    fulfillment.set_as_sent!
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
    member = FactoryGirl.create(:applied_member, terms_of_membership: @terms_of_membership_with_gateway, club: @terms_of_membership_with_gateway.club) 
    enrollment_info = FactoryGirl.create(:enrollment_info, :member_id => member.id)
    assert_difference('Fulfillment.count',2) do
      member.set_as_provisional!
    end
  end

  test "Should send fulfillments on acepted applied member and set correct status on fulfillments" do
    setup_products

    member = FactoryGirl.create(:applied_member, terms_of_membership: @terms_of_membership_with_gateway, club: @terms_of_membership_with_gateway.club) 
    enrollment_info = FactoryGirl.create(:enrollment_info_with_product_without_stock, :member_id => member.id)
    assert_difference('Fulfillment.count',2) do
      member.set_as_provisional!
    end
    fulfillment_out_of_stock = Fulfillment.find_by_product_sku('circlet')
    assert_equal fulfillment_out_of_stock.status, 'out_of_stock', "Status is #{fulfillment_out_of_stock.status} should be 'out_of_stock'"

    fulfillment_with_stock = Fulfillment.find_by_product_sku('Bracelet')
    assert_equal fulfillment_with_stock.status, 'not_processed', "Status is #{fulfillment_out_of_stock.status} should be 'not_processed'"          
  end

  test "Should create new fulfillment with recurrent and renewable_date" do
    setup_products
    member = FactoryGirl.create(:applied_member, terms_of_membership: @terms_of_membership_with_gateway, club: @terms_of_membership_with_gateway.club) 
    enrollment_info = FactoryGirl.create(:enrollment_info_with_product_recurrent, :member_id => member.id)
    assert_difference('Fulfillment.count') do
      member.set_as_provisional!
    end
    fulfillment_out_of_stock = Fulfillment.find_by_product_sku('kit-kard')
    assert_equal fulfillment_out_of_stock.recurrent, true, "Recurrent on fulfillment is not recurrent when it should be."
    assert_equal fulfillment_out_of_stock.renewable_at, fulfillment_out_of_stock.assigned_at + 1.year, "Renewable date was not set properly."
  end

  test "When resending fulfillment has stock, it should be set as not_processed" do
    setup_products
    agent = FactoryGirl.create(:confirmed_admin_agent)
    member = FactoryGirl.create(:applied_member, terms_of_membership: @terms_of_membership_with_gateway, club: @terms_of_membership_with_gateway.club) 
    fulfillment = FactoryGirl.create(:fulfillment_undeliverable_with_stock, :member_id => member.id)
    stock = fulfillment.product.stock
    fulfillment.resend(agent)
    assert_equal fulfillment.product.stock, stock, "Stock was decreased."
    assert_equal fulfillment.status, 'undeliverable', "Status should not be changed, since member's is undeliverable."
  end 
end
